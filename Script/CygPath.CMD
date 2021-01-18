::CygPath子程序
::@author FB
::@version 0.1

@ECHO OFF
CALL :%*
GOTO :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

##Bin:Cygpath.EXE##

::转换到CYG路径
::  参数1: Win路径
::  返回$: CYG路径
:TO_CYG_PATH
SET "$=%~1"
IF "%$:~-1%" == "\" SET "$=%$:~0,-1%"
FOR /F "tokens=* usebackq" %%I IN (`Cygpath.EXE -u "%$%"`) DO SET "$=%%I"
GOTO :EOF

::转换到WIN路径
::  参数1: CYG路径
::  返回$: Win路径
:TO_WIN_PATH
SET "$=%~1"
IF "%$:~-1%" == "/" SET "$=%$:~0,-1%"
FOR /F "tokens=* usebackq" %%I IN (`Cygpath.EXE -w "%$%"`) DO SET "$=%%I"
GOTO :EOF
