::CygPath�ӳ���
::@author FB
::@version 0.1

@ECHO OFF
CALL :%*
GOTO :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

#TO_CYG_PATH#
::ת����CYG·��
::  ����1: Win·��
::  ����$: CYG·��
:TO_CYG_PATH
SET "$=%~1"
IF "%$:~-1%" == "\" SET "$=%$:~0,-1%"
FOR /F "tokens=* usebackq" %%I IN (`CYGPATH.EXE -u "%$%"`) DO SET "$=%%I"
GOTO :EOF
#EOF#

#TO_WIN_PATH#
::ת����WIN·��
::  ����1: CYG·��
::  ����$: Win·��
:TO_WIN_PATH
SET "$=%~1"
IF "%$:~-1%" == "/" SET "$=%$:~0,-1%"
FOR /F "tokens=* usebackq" %%I IN (`CYGPATH.EXE -w "%$%"`) DO SET "$=%%I"
GOTO :EOF
#EOF#