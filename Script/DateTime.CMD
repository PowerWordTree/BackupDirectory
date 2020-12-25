::DateTime子程序
::@author FB
::@version 0.1

@ECHO OFF
CALL :%*
GOTO :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

#ECHO#
::带日期时间的输出
::  参数: 文字
:ECHO
CALL :GET_DATETIME
ECHO [%$%] %*
GOTO :EOF
#EOF#

#GET_DATE#
::获取日期
::  参数1: 日期(可选)
::  返回$: 日期字符串
:GET_DATE
SET "$="%~1""
IF "%~1" == "" SET "$='DATE /T'"
FOR /F "tokens=1,2,3,* delims=/.-\: " %%A IN (%$%) DO (
    SET "$=%%A-%%B-%%C"
)
GOTO :EOF
#EOF#

#GET_TIME#
::获取时间
::  参数1: 时间(可选)
::  返回$: 时间字符串
:GET_TIME
SET "$=%~1"
IF "%~1" == "" SET "$=%TIME%"
FOR /F "tokens=1,2,3,* delims=/.-\: " %%A IN ("%$%") DO (
    SET "$=%%A:%%B:%%C"
    IF "!$:~7!" == "" SET "$=0!$!"
)
GOTO :EOF
#EOF#

#GET_DATETIME#
::获取日期时间
::  参数1: 时间(可选)
::  返回$: 时间字符串
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
