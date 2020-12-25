::目录备份脚本
::@author FB
::@version 1.11

@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
CD /D "%~dp0"
SET "PATH=%CD%\Bin;%CD%\Script;%PATH%"
SET "RETURN=0"

::解析命令
::  BackupDirectory.CMD [配置[.cfg]]
IF "%~1" == "" (
    SET "CFG_FILE=%~dpn0.cfg"
) ELSE IF /I "%~x1" == ".cfg" (
    SET "CFG_FILE=%~f1"
) ELSE (
    SET "CFG_FILE=%~f1.cfg"
)
IF NOT EXIST "%CFG_FILE%" (
    ECHO.
    ECHO 配置文件不存在!
    SET "RETURN=1"
    GOTO :END
)
::读取配置
CALL DateTime.CMD ECHO 读取配置
CALL ConfigFile.CMD CLEAN_VARS "BACKUP_SRC" "BACKUP_DEST" 
CALL ConfigFile.CMD CLEAN_VARS "BACKUP_PASS" "BACKUP_RULES" 
CALL ConfigFile.CMD CLEAN_VARS "BACKUP_LIMIT" "BACKUP_EQUAL"
CALL ConfigFile.CMD READ_CONF "%CFG_FILE%"
ECHO 来源路径: %BACKUP_SRC%
ECHO 目标路径: %BACKUP_DEST%
ECHO 规则文件: %BACKUP_RULES%
ECHO 保留历史: %BACKUP_LIMIT%
ECHO 相同副本: %BACKUP_EQUAL%
::::处理参数
CALL CygPath.CMD TO_CYG_PATH "%BACKUP_SRC%"
SET "BACKUP_SRC=%$%"
CALL CygPath.CMD TO_CYG_PATH "%BACKUP_DEST%"
SET "BACKUP_DEST=%$%"
SET "RSYNC_PASSWORD=%BACKUP_PASS%"
SET "CYGWIN=winsymlinks:nativestrict"
SET "MSYS=%CYGWIN%"
SET "LANG=en_US.GBK"
SET "OUTPUT_CHARSET=GBK"
CALL Retry.CMD SET 2 30
SET "BACKUP_FILTER=--filter="merge Global.rules""
IF NOT "%BACKUP_RULES%" == "" (
    SET "BACKUP_FILTER=%BACKUP_FILTER% --filter="merge %BACKUP_RULES%""
)
IF 0%BACKUP_LIMIT% LEQ 0 SET "BACKUP_LIMIT=1"
CALL DateTime.CMD GET_DATETIME
SET "BACKUP_NAME=%$%"
SET "BACKUP_NAME=%BACKUP_NAME::=.%"
SET "BACKUP_NAME=%BACKUP_NAME: =_%"
::检查参数
CALL DateTime.CMD ECHO 检查参数
CALL Rsync.CMD PARAM_SET --archive --delete --compress --verbose --human-readable %BACKUP_FILTER% --exclude="*" "%BACKUP_SRC%" "%BACKUP_DEST%"
CALL Retry.CMD EXEC Rsync.CMD DRY_RUN >NUL
IF NOT "%ERRORLEVEL%" == "0" (
    ECHO 参数或配置文件有错误.
    SET "RETURN=%ERRORLEVEL%"
    GOTO :END
)
ECHO 模拟运行成功,参数正确.
::查询最新备份
CALL DateTime.CMD ECHO 查询最新备份
CALL Rsync.CMD PARAM_SET --include="/[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]_[0-2][0-9].[0-5][0-9].[0-5][0-9]/" --exclude="*" "%BACKUP_DEST%/"
CALL Retry.CMD EXEC Rsync.CMD GET_LIST_ARRAY "BACKUP_LIST"
IF NOT "%ERRORLEVEL%" == "0" (
    ECHO 查询备份列表时发生错误.
    SET "RETURN=%ERRORLEVEL%"
    GOTO :END
)
CALL Array.CMD SORT "BACKUP_LIST"
CALL Array.CMD GET "BACKUP_LIST"
SET "BACKUP_LAST=%$%"
CALL Array.CMD EACH "BACKUP_LIST" "ECHO {V}"
ECHO 使用"%BACKUP_LAST%"为基准路径
::比较目录文件
CALL DateTime.CMD ECHO 比较目录文件
CALL Rsync.CMD PARAM_SET --dry-run --archive --delete --compress --verbose --human-readable %BACKUP_FILTER% --link-dest="../%BACKUP_LAST%" "%BACKUP_SRC%/" "%BACKUP_DEST%/%BACKUP_NAME%"
CALL Retry.CMD EXEC Rsync.CMD GET_STATS_MAP "BACKUP_STATS"
IF NOT "%ERRORLEVEL%" == "0" (
    ECHO 比较文件和目录时发生错误.
    SET "RETURN=%ERRORLEVEL%"
    GOTO :END
)
CALL Map.CMD EACH "BACKUP_STATS" "ECHO {K}: {V}"
IF NOT "%BACKUP_STATS[Number of created files]%" == "0" SET "BACKUP_EQUAL=TRUE"
IF NOT "%BACKUP_STATS[Number of deleted files]%" == "0" SET "BACKUP_EQUAL=TRUE"
IF NOT "%BACKUP_STATS[Number of regular files transferred]%" == "0" SET "BACKUP_EQUAL=TRUE"
::同步目录文件
CALL DateTime.CMD ECHO 同步目录文件
IF /I NOT "%BACKUP_EQUAL%" == "TRUE" (
    ECHO 没有文件或目录改变,无需同步.
    GOTO :END
)
CALL Rsync.CMD PARAM_SET --archive --delete --compress --verbose --human-readable %BACKUP_FILTER% --link-dest="../%BACKUP_LAST%" "%BACKUP_SRC%/" "%BACKUP_DEST%/%BACKUP_NAME%"
CALL RETRY.CMD EXEC Rsync.CMD RUN 
IF NOT "%ERRORLEVEL%" == "0" (
    SET "RETURN=%ERRORLEVEL%"
    ECHO 执行同步失败,删除不完整备份.
    CALL Rsync.CMD PARAM_SET --archive --delete --no-motd --filter="hide *" --filter="risk /%BACKUP_NAME%" --filter="protect /*" "./" "%BACKUP_DEST%"
    CALL RETRY.CMD EXEC Rsync.CMD RUN
    ECHO 同步目录文件任务失败.
    GOTO :END
)
CALL Array.CMD PUSH "BACKUP_LIST" "%BACKUP_NAME%"
::清理过期备份
CALL DateTime.CMD ECHO 清理过期备份
IF 0%BACKUP_LIST% GTR 0%BACKUP_LIMIT% (
    CALL Rsync.CMD PARAM_SET --archive --delete --no-motd --filter="hide *"
    SET /A "BACKUP_CLEAN=!BACKUP_LIST! - !BACKUP_LIMIT! - 1"
    FOR /L %%I IN (0,1,!BACKUP_CLEAN!) DO (
        ECHO !BACKUP_LIST[%%~I]!
        CALL Rsync.CMD PARAM_ADD --filter="risk /!BACKUP_LIST[%%~I]!"
    )
    CALL Rsync.CMD PARAM_ADD --filter="protect /*" "./" "%BACKUP_DEST%"
    CALL RETRY.CMD EXEC Rsync.CMD RUN
    IF NOT "!ERRORLEVEL!" == "0" (
        ECHO 删除过期备份目录任务失败.
        SET "RETURN=!ERRORLEVEL!"
        GOTO :END
    )
) ELSE (
    ECHO 未发现过期备份,无需清理.
)
::执行结束
:END
IF "%RETURN%" == "0" (
    CALL DateTime.CMD ECHO 执行备份成功
) ELSE (
    CALL DateTime.CMD ECHO 执行备份失败
)
EXIT /B %RETURN%
