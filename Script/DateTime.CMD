::DateTime�ӳ���
::@author FB
::@version 0.1

@ECHO OFF
CALL :%*
GOTO :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

#ECHO#
::������ʱ������
::  ����: ����
:ECHO
CALL :GET_DATETIME
ECHO [%$%] %*
GOTO :EOF
#EOF#

#GET_DATE#
::��ȡ����
::  ����1: ����(��ѡ)
::  ����$: �����ַ���
:GET_DATE
SET "$="%~1""
IF "%~1" == "" SET "$='DATE /T'"
FOR /F "tokens=1,2,3,* delims=/.-\: " %%A IN (%$%) DO (
    SET "$=%%A-%%B-%%C"
)
GOTO :EOF
#EOF#

#GET_TIME#
::��ȡʱ��
::  ����1: ʱ��(��ѡ)
::  ����$: ʱ���ַ���
:GET_TIME
SET "$=%~1"
IF "%~1" == "" SET "$=%TIME%"
FOR /F "tokens=1,2,3,* delims=/.-\: " %%A IN ("%$%") DO (
    SET "$=%%A:%%B:%%C"
)
GOTO :EOF
#EOF#

#GET_DATETIME#
::��ȡ����ʱ��
::  ����1: ʱ��(��ѡ)
::  ����$: ʱ���ַ���
:GET_DATETIME
SET "$DATETIME=%~1"
IF "%$DATETIME%" == "" (
    CALL :GET_DATE
    SET "$DATETIME=!$!"
    CALL :GET_TIME
    SET "$DATETIME=!$DATETIME! !$!"
)
FOR /F "tokens=1-6,* delims=/.-\: " %%A IN ("%$DATETIME%") DO (
    SET "$=%%A-%%B-%%C %%D:%%E:%%F"
)
SET "$DATETIME="
GOTO :EOF
#EOF#