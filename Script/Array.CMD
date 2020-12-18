::数组子程序
::@author FB
::@version 0.1

@ECHO OFF
CALL :%*
GOTO :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

#NEW#
::数组创建
::  参数1: 变量名
:NEW
SET "%~1=0"
GOTO :EOF
#EOF#

#DESTROY#
##REQUIRE:EACH
::数组销毁
::  参数1: 变量名
:DESTROY
CALL :EACH "%~1" "SET %~1[{K}]="
SET "%~1="
GOTO :EOF
#EOF#

#CLEAR#
##REQUIRE:NEW,DESTROY
::数组创建
::  参数1: 变量名
:CLEAR
CALL :DESTROY "%~1"
CALL :NEW "%~1"
GOTO :EOF
#EOF#

#PUSH#
::数组压入
::  参数1: 变量名
::  参数2: 元素
:PUSH
CALL SET "%~1[%%%~1%%]=%~2"
SET /A "%~1+=1"
GOTO :EOF
#EOF#

#POP#
::数组弹出
::  参数1: 变量名
::  返回$: 元素
:POP
SET /A "%~1-=1"
CALL CALL SET "$=%%%%%~1[%%%~1%%]%%%%"
CALL SET "%~1[%%%~1%%]="
GOTO :EOF
#EOF#

#GET#
::数组读取
::  参数1: 变量名
::  参数2: 索引号(可选,默认最后一个)
:GET
SET "$=%~2"
IF "%$%" == "" CALL SET /A "$=%%%~1%% - 1"
CALL SET "$=%%%~1[%$%]%%"
GOTO :EOF
#EOF#

#EACH#
::数组遍历
::  参数1: 变量名
::  参数2: 回调命令({K}替代变量索引, {V}替代变量内容)
:EACH
ECHO ===========
SET /A "$=!%~1! - 1"
FOR /L %%I IN (0,1,%$%) DO (
    SET "$=%~2"
    CALL SET "$=%%$:{K}=%%~I%%"
    CALL SET "$=%%$:{V}=!%~1[%%I]!%%"
    CALL %%$%%
)
GOTO :EOF
#EOF#

#SORT#
::数组排序
::  参数1: 变量名
:SORT
SET /A "$LAST=!%~1! - 1"
FOR /L %%I IN (1,1,!$LAST!) DO (
  FOR /L %%J IN (!$LAST!,-1,%%I) DO (
    SET /A "$PREV=%%J - 1"
    CALL CALL SET "$=%%%%%~1[%%$PREV%%]%%%%"
    IF "!$!" GTR "!%~1[%%J]!" (
      CALL SET "%~1[%%$PREV%%]=%%%~1[%%J]%%"
      CALL SET "%~1[%%J]=%%$%%"
    )
  )
)
SET "$PREV="
SET "$LAST="
GOTO :EOF
#EOF#
