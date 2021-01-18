::执行并生成日志
::@author FB
::@version 1.01

@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
CD /D "%~dp0"
SET "PATH=%CD%\Bin;%CD%\Script;%PATH%"
SET "RETURN=0"

SET "LOG_PATH=LOG"
SET "LOG_LIMIT=1"

::创建日志目录
IF NOT EXIST "%LOG_PATH%" MKDIR "%LOG_PATH%"
::获取任务列表
SET "RUN_CFG="
FOR /F "tokens=* usebackq" %%A IN (`DIR /B *.CFG 2^>NUL`) DO (
    SET "RUN_CFG=!RUN_CFG! "%%~nA""
)
::开始执行任务
FOR %%I IN (%RUN_CFG%) DO (
    ::获取当前日期
    CALL DateTime.CMD GET_DATE
    SET "LOG_DATE=!$!"
    ::执行并生成日志
    CALL BackupDirectory.CMD "%%~I" 1>>"%LOG_PATH%\%%~I_!LOG_DATE!.LOG" 2>>&1
    IF NOT "!ERRORLEVEL!" == "0" (
        SET /A "RETURN+=1"
        MOVE /Y "%LOG_PATH%\%%~I_!LOG_DATE!.LOG" "%LOG_PATH%\%%~I_!LOG_DATE!_ERROR.LOG" 1>NUL 2>&1
    ) ELSE (
        DEL /Q /F "%LOG_PATH%\%%~I_!LOG_DATE!_ERROR.LOG" 1>NUL 2>&1
    )
    ::清理日志
    FOR /F "tokens=1,* usebackq delims=[]" %%A IN (
        `DIR /B "%LOG_PATH%\%%~I_*.LOG" 2^>NUL ^| SORT /R ^| FIND /V /N ""`
    ) DO (
        IF 0%%A GTR 0%LOG_LIMIT% DEL /Q /F "%LOG_PATH%\%%B" 1>NUL 2>&1
    )
)
::执行结束
EXIT /B %RETURN%
