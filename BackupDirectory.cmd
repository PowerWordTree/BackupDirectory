::Ŀ¼���ݽű�
::@author FB
::@version 1.10

@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
CD /D "%~dp0"
SET "PATH=%CD%\Bin;C:\Develop\Workspaces\CmdTools\Script;%PATH%"
SET "RETURN=0"

::��������
::::BackupDirectory.CMD [����[.cfg]]
IF "%~1" == "" (
    SET "CFG_FILE=%~dpn0.cfg"
) ELSE IF /I "%~x1" == ".cfg" (
    SET "CFG_FILE=%~f1"
) ELSE (
    SET "CFG_FILE=%~f1.cfg"
)
::::���������ļ�
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
::������
CALL DateTime.CMD ECHO ������
CALL RSYNC.CMD PARAM_SET %BACKUP_ARG% --exclude="*"
CALL RETRY.CMD EXEC RSYNC.CMD DRY_RUN "%BACKUP_SRC%" "%BACKUP_DEST%" >NUL
IF NOT "%ERRORLEVEL%" == "0" (
    ECHO �����������ļ��д���.
    SET "RETURN=%$%"
    GOTO :END
)
ECHO ģ�����гɹ�,������ȷ.
::��ѯ���±���
CALL DateTime.CMD ECHO ��ѯ���±���
CALL Array.CMD NEW "BACKUP_LIST"
CALL RSYNC.CMD PARAM_SET --no-motd --include="/*/" --exclude="*"
FOR /F "tokens=1-4,* usebackq" %%A IN (
    `CMD /V:ON /C RETRY.CMD EXEC RSYNC.CMD LIST "%BACKUP_DEST%/" ^|^| ECHO LiSt:ErrOr`
) DO (
    IF "%%~A" == "LiSt:ErrOr" (
        ECHO ��ѯ�����б�ʱ��������.
        SET "RETURN=1"
        GOTO :END
    )
    ECHO %%~E | FINDSTR /I /X /R /C:"[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]_[0-2][0-9]\.[0-5][0-9]\.[0-5][0-9] "
    IF "!ERRORLEVEL!" == "0" CALL Array.CMD PUSH "BACKUP_LIST" "%%~E"
)
CALL Array.CMD SORT "BACKUP_LIST"
CALL Array.CMD GET "BACKUP_LIST"
SET "BACKUP_LAST=%$%"
ECHO ʹ��"%BACKUP_LAST%"Ϊ��׼·��
::�Ƚ�Ŀ¼�ļ�
CALL DateTime.CMD ECHO �Ƚ�Ŀ¼�ļ�
SET /A "BACKUP_COUNT=0"
CALL RSYNC.CMD PARAM_SET %BACKUP_ARG% --no-motd --link-dest="../%BACKUP_LAST%" 
FOR /F "tokens=* usebackq" %%A IN (
    `CMD /V:ON /C RETRY.CMD EXEC RSYNC.CMD DRY_RUN "%BACKUP_SRC%/" "%BACKUP_DEST%/%BACKUP_NAME%" ^|^| ECHO CoMp:ErrOr`
) DO (
    IF "%%~A" == "CoMp:ErrOr" (
        ECHO �Ƚ��ļ���Ŀ¼ʱ��������.
        SET "RETURN=1"
        GOTO :END
    )
    ECHO %%~A | FINDSTR /V /I /R /C:"building file list .*" /C:"sending incremental file list" /C:"created directory .*" /C:"\./" /C:"sent .* received .*" /C:"total size is .* speedup is .*" 1>NUL 2>&1
    IF "!ERRORLEVEL!" == "0" SET /A "BACKUP_COUNT+=1"
)
ECHO ��ͬ�����ļ���Ŀ¼����: !BACKUP_COUNT!
::ͬ��Ŀ¼�ļ�
CALL DateTime.CMD ECHO ͬ��Ŀ¼�ļ�
IF "%BACKUP_COUNT%" == "0" IF /I NOT "%BACKUP_EQUAL%" == "TRUE" (
    ECHO û���ļ���Ŀ¼�ı�,����ͬ��.
    GOTO :END
)
CALL RSYNC.CMD PARAM_SET %BACKUP_ARG% --link-dest="../%BACKUP_LAST%"
CALL RETRY.CMD EXEC RSYNC.CMD RUN "%BACKUP_SRC%/" "%BACKUP_DEST%/%BACKUP_NAME%"
IF NOT "%ERRORLEVEL%" == "0" (
    ECHO ִ��ͬ��ʧ��,ɾ������������.
    CALL RSYNC.CMD PARAM_SET --archive --delete --no-motd --filter="hide *" --filter="risk /%BACKUP_NAME%*" --filter="protect /*"
    CALL RETRY.CMD EXEC RSYNC.CMD RUN "./" "%BACKUP_DEST%"
    ECHO ͬ��Ŀ¼�ļ�����ʧ��.
    SET "RETURN=1"
    GOTO :END
)
SET "BACKUP_LIST[!BACKUP_LIST!]=%BACKUP_LAST%"
SET /A "BACKUP_LIST+=1"
::������ڱ���
CALL DateTime.CMD ECHO ������ڱ���
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
