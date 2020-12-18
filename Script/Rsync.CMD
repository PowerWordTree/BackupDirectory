::Rsync子程序
::@author FB
::@version 0.1

@ECHO OFF
CALL :%*
GOTO :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

#PARAM_SET#
::替换参数
::  参数N: 参数
:PARAM_SET
SET "RSYNC_PARAMS=%*"
GOTO :EOF
#EOF#

#PARAM_ADD#
::添加参数
::  参数N: 要添加的参数
:PARAM_ADD
SET "RSYNC_PARAMS=%RSYNC_PARAMS% %*"
GOTO :EOF
#EOF#

#RUN#
::运行
::  参数1: 源路径
::  参数2: 目标路径
:RUN
RSYNC.EXE %RSYNC_PARAMS% %1 %2
GOTO :EOF
#EOF#

#RUN#
::模拟运行
::  参数1: 源路径
::  参数2: 目标路径
:DRY_RUN
RSYNC.EXE %RSYNC_PARAMS% --dry-run %1 %2
GOTO :EOF
#EOF#

#RUN#
::列出文件列表
::  参数1: 源路径
:LIST
RSYNC.EXE %RSYNC_PARAMS% --list-only %1
GOTO :EOF
#EOF#
