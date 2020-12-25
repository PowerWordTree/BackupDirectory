::Ŀ¼���ݽű�
::@author FB
::@version 1.11

@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
CD /D "%~dp0"
SET "PATH=%CD%\Bin;%CD%\Script;%PATH%"
SET "RETURN=0"

::��������
::  BackupDirectory.CMD [����[.cfg]]
IF "%~1" == "" (
    SET "CFG_FILE=%~dpn0.cfg"
) ELSE IF /I "%~x1" == ".cfg" (
    SET "CFG_FILE=%~f1"
) ELSE (
    SET "CFG_FILE=%~f1.cfg"
)
IF NOT EXIST "%CFG_FILE%" (
    ECHO.
    ECHO �����ļ�������!
    SET "RETURN=1"
    GOTO :END
)
::��ȡ����
CALL DateTime.CMD ECHO ��ȡ����
CALL ConfigFile.CMD CLEAN_VARS "BACKUP_SRC" "BACKUP_DEST" 
CALL ConfigFile.CMD CLEAN_VARS "BACKUP_PASS" "BACKUP_RULES" 
CALL ConfigFile.CMD CLEAN_VARS "BACKUP_LIMIT" "BACKUP_EQUAL"
CALL ConfigFile.CMD READ_CONF "%CFG_FILE%"
ECHO ��Դ·��: %BACKUP_SRC%
ECHO Ŀ��·��: %BACKUP_DEST%
ECHO �����ļ�: %BACKUP_RULES%
ECHO ������ʷ: %BACKUP_LIMIT%
ECHO ��ͬ����: %BACKUP_EQUAL%
::::�������
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
::������
CALL DateTime.CMD ECHO ������
CALL Rsync.CMD PARAM_SET --archive --delete --compress --verbose --human-readable %BACKUP_FILTER% --exclude="*" "%BACKUP_SRC%" "%BACKUP_DEST%"
CALL Retry.CMD EXEC Rsync.CMD DRY_RUN >NUL
IF NOT "%ERRORLEVEL%" == "0" (
    ECHO �����������ļ��д���.
    SET "RETURN=%ERRORLEVEL%"
    GOTO :END
)
ECHO ģ�����гɹ�,������ȷ.
::��ѯ���±���
CALL DateTime.CMD ECHO ��ѯ���±���
CALL Rsync.CMD PARAM_SET --include="/[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]_[0-2][0-9].[0-5][0-9].[0-5][0-9]/" --exclude="*" "%BACKUP_DEST%/"
CALL Retry.CMD EXEC Rsync.CMD GET_LIST_ARRAY "BACKUP_LIST"
IF NOT "%ERRORLEVEL%" == "0" (
    ECHO ��ѯ�����б�ʱ��������.
    SET "RETURN=%ERRORLEVEL%"
    GOTO :END
)
CALL Array.CMD SORT "BACKUP_LIST"
CALL Array.CMD GET "BACKUP_LIST"
SET "BACKUP_LAST=%$%"
CALL Array.CMD EACH "BACKUP_LIST" "ECHO {V}"
ECHO ʹ��"%BACKUP_LAST%"Ϊ��׼·��
::�Ƚ�Ŀ¼�ļ�
CALL DateTime.CMD ECHO �Ƚ�Ŀ¼�ļ�
CALL Rsync.CMD PARAM_SET --dry-run --archive --delete --compress --verbose --human-readable %BACKUP_FILTER% --link-dest="../%BACKUP_LAST%" "%BACKUP_SRC%/" "%BACKUP_DEST%/%BACKUP_NAME%"
CALL Retry.CMD EXEC Rsync.CMD GET_STATS_MAP "BACKUP_STATS"
IF NOT "%ERRORLEVEL%" == "0" (
    ECHO �Ƚ��ļ���Ŀ¼ʱ��������.
    SET "RETURN=%ERRORLEVEL%"
    GOTO :END
)
CALL Map.CMD EACH "BACKUP_STATS" "ECHO {K}: {V}"
IF NOT "%BACKUP_STATS[Number of created files]%" == "0" SET "BACKUP_EQUAL=TRUE"
IF NOT "%BACKUP_STATS[Number of deleted files]%" == "0" SET "BACKUP_EQUAL=TRUE"
IF NOT "%BACKUP_STATS[Number of regular files transferred]%" == "0" SET "BACKUP_EQUAL=TRUE"
::ͬ��Ŀ¼�ļ�
CALL DateTime.CMD ECHO ͬ��Ŀ¼�ļ�
IF /I NOT "%BACKUP_EQUAL%" == "TRUE" (
    ECHO û���ļ���Ŀ¼�ı�,����ͬ��.
    GOTO :END
)
CALL Rsync.CMD PARAM_SET --archive --delete --compress --verbose --human-readable %BACKUP_FILTER% --link-dest="../%BACKUP_LAST%" "%BACKUP_SRC%/" "%BACKUP_DEST%/%BACKUP_NAME%"
CALL RETRY.CMD EXEC Rsync.CMD RUN 
IF NOT "%ERRORLEVEL%" == "0" (
    SET "RETURN=%ERRORLEVEL%"
    ECHO ִ��ͬ��ʧ��,ɾ������������.
    CALL Rsync.CMD PARAM_SET --archive --delete --no-motd --filter="hide *" --filter="risk /%BACKUP_NAME%" --filter="protect /*" "./" "%BACKUP_DEST%"
    CALL RETRY.CMD EXEC Rsync.CMD RUN
    ECHO ͬ��Ŀ¼�ļ�����ʧ��.
    GOTO :END
)
CALL Array.CMD PUSH "BACKUP_LIST" "%BACKUP_NAME%"
::������ڱ���
CALL DateTime.CMD ECHO ������ڱ���
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
        ECHO ɾ�����ڱ���Ŀ¼����ʧ��.
        SET "RETURN=!ERRORLEVEL!"
        GOTO :END
    )
) ELSE (
    ECHO δ���ֹ��ڱ���,��������.
)
::ִ�н���
:END
IF "%RETURN%" == "0" (
    CALL DateTime.CMD ECHO ִ�б��ݳɹ�
) ELSE (
    CALL DateTime.CMD ECHO ִ�б���ʧ��
)
EXIT /B %RETURN%
