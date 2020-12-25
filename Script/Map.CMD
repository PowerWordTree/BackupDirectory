::Map子程序
::@author FB
::@version 0.1

@ECHO OFF
CALL :%*
GOTO :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

#NEW#
::创建Map
::  参数1: 变量名
:NEW
SET "%~1=0"
GOTO :EOF
#EOF#

#DESTROY#
##REQUIRE:EACH
::销毁Map
::  参数1: 变量名
:DESTROY
CALL :EACH "%~1" "SET %~1[{K}]="
SET "%~1="
GOTO :EOF
#EOF#

#CLEAR#
##REQUIRE:NEW,DESTROY
::清空Map
::  参数1: 变量名
:CLEAR
CALL :DESTROY "%~1"
CALL :NEW "%~1"
GOTO :EOF
#EOF#

#PUT#
::加入Map
::  参数1: 变量名
::  参数2: 键
::  参数3: 值
:PUT
SET "%~1[%~2]=%~3"
SET /A "%~1+=1"
GOTO :EOF
#EOF#

#REMOVE#
::移出Map
::  参数1: 变量名
::  参数2: 键
::  返回$: 值
:REMOVE
SET /A "%~1-=1"
CALL SET "$=%%%~1[%~2]%%"
SET "%~1[%~2]="
GOTO :EOF
#EOF#

#GET#
::读取Map
::  参数1: 变量名
::  参数2: 键
:GET
CALL SET "$=%%%~1[%~2]%%"
GOTO :EOF
#EOF#

#EACH#
::遍历Map
::  参数1: 变量名
::  参数2: 回调命令({K}替代键, {V}替代值)
:EACH
FOR /F "tokens=1,2,* usebackq delims=[]=" %%A IN (`SET %~1[`) DO (
    SET "$=%~2"
    CALL SET "$=%%$:{K}=%%~B%%"
    CALL SET "$=%%$:{V}=%%~C%%"
    CALL %%$%%
)
GOTO :EOF
#EOF#
