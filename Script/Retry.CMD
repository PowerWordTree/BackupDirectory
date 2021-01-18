::Retry子程序
::@author FB
::@version 0.1

@ECHO OFF
CALL :%*
GOTO :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

##Script:Common.CMD##

::设置参数
::  参数1: 重试次数
::  参数2: 延迟时间(秒)
:SET
SET "RETRY_COUNT=%~1"
SET "RETRY_DELAY=%~2"
GOTO :EOF

::重试执行
::  参数N: 执行参数
:EXEC
FOR /L %%I IN (%RETRY_COUNT%,-1,0) DO (
    CALL %*
    IF "!ERRORLEVEL!" == "0" GOTO :EOF
    IF NOT "%%I" == "0" CALL Common.CMD SLEEP "%RETRY_DELAY%"
)
GOTO :EOF
