::Retry子程序
::@author FB
::@version 0.1

@ECHO OFF
CALL :%*
GOTO :EOF

:SLEEP
CALL Common.CMD SLEEP %*
GOTO :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

#SET#
::设置参数
::  参数1: 重试次数
::  参数2: 延迟时间(秒)
:SET
SET "RETRY_COUNT=%~1"
SET "RETRY_DELAY=%~2"
GOTO :EOF
#EOF#

#EXEC#
##REQUIRE:SLEEP
:EXEC
SET /A "$=%RETRY_COUNT% - 0"
FOR /L %%I IN (%$%,-1,0) DO (
    CALL %*
    IF "!ERRORLEVEL!" == "0" GOTO :EOF
    IF NOT "%%I" == "0" CALL :SLEEP "%RETRY_DELAY%"
)
GOTO :EOF
#EOF#
