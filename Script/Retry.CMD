::Retry�ӳ���
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
::���ò���
::  ����1: ���Դ���
::  ����2: �ӳ�ʱ��(��)
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