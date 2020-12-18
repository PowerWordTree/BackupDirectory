::目录备份脚本
::@author FB
::@version 1.10

@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
CD /D "%~dp0"
SET "PATH=%CD%\Bin;C:\Develop\Workspaces\CmdTools\Script;%PATH%"
SET "RETURN=0"

::解析命令
::::BackupDirectory.CMD [配置[.cfg]]
IF "%~1" == "" (
    SET "CFG_FILE=%~dpn0.cfg"
) ELSE IF /I "%~x1" == ".cfg" (
    SET "CFG_FILE=%~f1"
) ELSE (
    SET "CFG_FILE=%~f1.cfg"
)
::::测试配置文件
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
SET "LANG=zh_CN.GBK"
SET "OUTPUT_CHARSET=GBK"
CALL RETRY.CMD SET 2 30
SET "BACKUP_ARG=--archive --delete --compress --verbose --human-readable"
SET "BACKUP_ARG=%BACKUP_ARG% --filter="merge Global.rules""
IF NOT "%BACKUP_RULES%" == "" (
    SET "BACKUP_ARG=%BACKUP_ARG% --filter="merge %BACKUP_RULES%""
)
IF 0%BACKUP_LIMIT% LEQ 0 SET "BACKUP_LIMIT=1"
CALL DateTime.CMD GET_DATETIME
SET "BACKUP_NAME=%$%"
SET "BACKUP_NAME=%BACKUP_NAME::=.%"
SET "BACKUP_NAME=%BACKUP_NAME: =_%"
::检查参数
CALL DateTime.CMD ECHO 检查参数
CALL RSYNC.CMD PARAM_SET %BACKUP_ARG% --exclude="*"
CALL RETRY.CMD EXEC RSYNC.CMD DRY_RUN "%BACKUP_SRC%" "%BACKUP_DEST%" >NUL
IF NOT "%ERRORLEVEL%" == "0" (
    ECHO 参数或配置文件有错误.
    SET "RETURN=%$%"
    GOTO :END
)
ECHO 模拟运行成功,参数正确.
::查询最新备份
CALL DateTime.CMD ECHO 查询最新备份
CALL Array.CMD NEW "BACKUP_LIST"
CALL RSYNC.CMD PARAM_SET --no-motd --include="/*/" --exclude="*"
FOR /F "tokens=1-4,* usebackq" %%A IN (
    `CMD /V:ON /C RETRY.CMD EXEC RSYNC.CMD LIST "%BACKUP_DEST%/" ^|^| ECHO LiSt:ErrOr`
) DO (
    IF "%%~A" == "LiSt:ErrOr" (
        ECHO 查询备份列表时发生错误.
        SET "RETURN=1"
        GOTO :END
    )
    ECHO %%~E | FINDSTR /I /X /R /C:"[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]_[0-2][0-9]\.[0-5][0-9]\.[0-5][0-9] "
    IF "!ERRORLEVEL!" == "0" CALL Array.CMD PUSH "BACKUP_LIST" "%%~E"
)
CALL Array.CMD SORT "BACKUP_LIST"
CALL Array.CMD GET "BACKUP_LIST"
SET "BACKUP_LAST=%$%"
ECHO 使用"%BACKUP_LAST%"为基准路径
::比较目录文件
CALL DateTime.CMD ECHO 比较目录文件
SET /A "BACKUP_COUNT=0"
CALL RSYNC.CMD PARAM_SET %BACKUP_ARG% --no-motd --link-dest="../%BACKUP_LAST%" 
FOR /F "tokens=* usebackq" %%A IN (
    `CMD /V:ON /C RETRY.CMD EXEC RSYNC.CMD DRY_RUN "%BACKUP_SRC%/" "%BACKUP_DEST%/%BACKUP_NAME%" ^|^| ECHO CoMp:ErrOr`
) DO (
    IF "%%~A" == "CoMp:ErrOr" (
        ECHO 比较文件和目录时发生错误.
        SET "RETURN=1"
        GOTO :END
    )
    ECHO %%~A | FINDSTR /V /I /R /C:"building file list .*" /C:"sending incremental file list" /C:"created directory .*" /C:"\./" /C:"sent .* received .*" /C:"total size is .* speedup is .*" 1>NUL 2>&1
    IF "!ERRORLEVEL!" == "0" SET /A "BACKUP_COUNT+=1"
)
ECHO 需同步的文件和目录数量: !BACKUP_COUNT!
::同步目录文件
CALL DateTime.CMD ECHO 同步目录文件
IF "%BACKUP_COUNT%" == "0" IF /I NOT "%BACKUP_EQUAL%" == "TRUE" (
    ECHO 没有文件或目录改变,无需同步.
    GOTO :END
)
CALL RSYNC.CMD PARAM_SET %BACKUP_ARG% --link-dest="../%BACKUP_LAST%"
CALL RETRY.CMD EXEC RSYNC.CMD RUN "%BACKUP_SRC%/" "%BACKUP_DEST%/%BACKUP_NAME%"
IF NOT "%ERRORLEVEL%" == "0" (
    ECHO 执行同步失败,删除不完整备份.
    CALL RSYNC.CMD PARAM_SET --archive --delete --no-motd --filter="hide *" --filter="risk /%BACKUP_NAME%*" --filter="protect /*"
    CALL RETRY.CMD EXEC RSYNC.CMD RUN "./" "%BACKUP_DEST%"
    ECHO 同步目录文件任务失败.
    SET "RETURN=1"
    GOTO :END
)
SET "BACKUP_LIST[!BACKUP_LIST!]=%BACKUP_LAST%"
SET /A "BACKUP_LIST+=1"
::清理过期备份
CALL DateTime.CMD ECHO 清理过期备份
IF 0%BACKUP_LIST% GTR 0%BACKUP_LIMIT% (
    SET "BACKUP_CLEAN="
    SET /A "DEL=!BACKUP_LIST! - !BACKUP_LIMIT! - 1"
    FOR /L %%I IN (0,1,!DEL!) DO (
        ECHO !BACKUP_LIST[%%~I]!
        SET "BACKUP_CLEAN=!BACKUP_CLEAN! --filter="risk /!BACKUP_LIST[%%~I]!*""
    )
    CALL RSYNC.CMD PARAM_SET --archive --delete --no-motd --filter="hide *" !BACKUP_CLEAN! --filter="protect /*"
    CALL RETRY.CMD EXEC RSYNC.CMD RUN "./" "%BACKUP_DEST%"
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
