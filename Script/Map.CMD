::Map�ӳ���
::@author FB
::@version 0.1

@ECHO OFF
CALL :%*
GOTO :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

#NEW#
::����Map
::  ����1: ������
:NEW
SET "%~1=0"
GOTO :EOF
#EOF#

#DESTROY#
##REQUIRE:EACH
::����Map
::  ����1: ������
:DESTROY
CALL :EACH "%~1" "SET %~1[{K}]="
SET "%~1="
GOTO :EOF
#EOF#

#CLEAR#
##REQUIRE:NEW,DESTROY
::���Map
::  ����1: ������
:CLEAR
CALL :DESTROY "%~1"
CALL :NEW "%~1"
GOTO :EOF
#EOF#

#PUT#
::����Map
::  ����1: ������
::  ����2: ��
::  ����3: ֵ
:PUT
SET "%~1[%~2]=%~3"
SET /A "%~1+=1"
GOTO :EOF
#EOF#

#REMOVE#
::�Ƴ�Map
::  ����1: ������
::  ����2: ��
::  ����$: ֵ
:REMOVE
SET /A "%~1-=1"
CALL SET "$=%%%~1[%~2]%%"
SET "%~1[%~2]="
GOTO :EOF
#EOF#

#GET#
::��ȡMap
::  ����1: ������
::  ����2: ��
:GET
CALL SET "$=%%%~1[%~2]%%"
GOTO :EOF
#EOF#

#EACH#
::����Map
::  ����1: ������
::  ����2: �ص�����({K}�����, {V}���ֵ)
:EACH
FOR /F "tokens=1,2,* usebackq delims=[]=" %%A IN (`SET %~1[`) DO (
    SET "$=%~2"
    CALL SET "$=%%$:{K}=%%~B%%"
    CALL SET "$=%%$:{V}=%%~C%%"
    CALL %%$%%
)
GOTO :EOF
#EOF#