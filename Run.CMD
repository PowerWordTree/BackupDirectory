@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
CD /D "%~dp0"
SET "RETURN=0"

SET "LOG_PATH=LOG"
SET "LOG_LIMIT=1"

::������־Ŀ¼
IF NOT EXIST "%LOG_PATH%" MKDIR "%LOG_PATH%"
::��ȡ�����б�
SET "RUN_CFG="
FOR /F "tokens=* usebackq" %%A IN (`DIR /B *.CFG 2^>NUL`) DO (
    SET "RUN_CFG=!RUN_CFG! "%%~nA""
)
::��ʼִ������
FOR %%I IN (%RUN_CFG%) DO (
    ::��ȡ��ǰ����
    FOR /F "tokens=1,2,3,* usebackq delims=/.-\: " %%A IN (`DATE /T`) DO (
        SET "LOG_DATE=%%A-%%B-%%C"
    )
    ::ִ�в�������־
    CALL BackupDirectory.CMD "%%~I" 1>>"%LOG_PATH%\%%~I_!LOG_DATE!.LOG" 2>>&1
    IF NOT "!ERRORLEVEL!" == "0" (
        SET /A "RETURN+=1"
        MOVE /Y "%LOG_PATH%\%%~I_!LOG_DATE!.LOG" "%LOG_PATH%\%%~I_!LOG_DATE!_ERROR.LOG" 1>NUL 2>&1
    ) ELSE (
        DEL /Q /F "%LOG_PATH%\%%~I_!LOG_DATE!_ERROR.LOG" 1>NUL 2>&1
    )
    ::������־
    FOR /F "tokens=1,* usebackq delims=[]" %%A IN (
        `DIR /B "%LOG_PATH%\%%~I_*" 2^>NUL ^| SORT /R ^| FIND /V /N ""`
    ) DO (
        IF 0%%A GTR 0%LOG_LIMIT% DEL /Q /F "%LOG_PATH%\%%B" 1>NUL 2>&1
    )
)
::ִ�н���
EXIT /B %RETURN%