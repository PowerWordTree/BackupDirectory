::Rsync子程序
::@author FB
::@version 0.1

@ECHO OFF
CALL :%*
GOTO :EOF

:COMMON_TRIM
CALL Common.CMD TRIM %*
GOTO :EOF

:ARRAY_NEW
CALL Array.CMD NEW %*
GOTO :EOF
:ARRAY_DESTROY
CALL Array.CMD DESTROY %*
GOTO :EOF
:ARRAY_PUSH
CALL Array.CMD PUSH %*
GOTO :EOF
:ARRAY_POP
CALL Array.CMD POP %*
GOTO :EOF

:MAP_NEW
CALL Map.CMD NEW %*
GOTO :EOF
:MAP_DESTROY
CALL Map.CMD DESTROY %*
GOTO :EOF
:MAP_PUT
CALL Map.CMD PUT %*
GOTO :EOF
:MAP_REMOVE
CALL Map.CMD REMOVE %*
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
:RUN
Rsync.EXE %RSYNC_PARAMS%
GOTO :EOF
#EOF#

#DRY_RUN#
::模拟运行
:DRY_RUN
Rsync.EXE --dry-run %RSYNC_PARAMS%
GOTO :EOF
#EOF#

#LIST#
::获取列表
:LIST
Rsync.EXE --list-only %RSYNC_PARAMS%
GOTO :EOF
#EOF#

#GET_TRANSFER_ARRAY#
##REQUIRE:ARRAY_NEW,ARRAY_DESTROY,ARRAY_PUSH,ARRAY_POP
::执行输出到数组
::  参数1: 输出变量名
::  返回$: 返回码
:GET_TRANSFER_ARRAY
CALL :ARRAY_NEW "%~1"
FOR /F "tokens=* usebackq" %%A IN (
    `CMD /V:ON /C "Rsync.EXE %RSYNC_PARAMS% --no-motd --verbose & "Echo.EXE" !ERRORLEVEL!" ^| UNIX2DOS.EXE ^| FINDSTR /V /I /X /R /C:"building file list .*" /C:"sending incremental file list" /C:"created directory .*" /C:"\./" /C:"sent .* received .*" /C:"total size is .* speedup is .*"`
) DO (
    CALL :ARRAY_NEW "%~1" "%%~A"
)
CALL :ARRAY_POP "%~1"
IF NOT "%$%" == "0" CALL :ARRAY_DESTROY "%~1"
EXIT /B %$%
GOTO :EOF
#EOF#

#GET_STATS_MAP#
##REQUIRE:COMMON_TRIM,MAP_NEW,MAP_DESTROY,MAP_PUT,MAP_REMOVE
::执行并
::  参数1: 输出变量名
::  返回$: 返回码
:GET_STATS_MAP
CALL :MAP_NEW "%~1"
FOR /F "tokens=1,* usebackq delims=:" %%A IN (
    `CMD /V:ON /C "Rsync.EXE %RSYNC_PARAMS% --stats --no-motd --no-verbose & "Echo.EXE" ERRORLEVEL:!ERRORLEVEL!" ^| UNIX2DOS.EXE ^| FINDSTR ":"`
) DO (
    CALL :COMMON_TRIM "%%~B"
    CALL :MAP_PUT "%~1" "%%~A" "%%$%%"
)
CALL :MAP_REMOVE "%~1" "ERRORLEVEL"
IF NOT "%$%" == "0" CALL :MAP_DESTROY "%~1"
EXIT /B %$%
GOTO :EOF
#EOF#

#GET_LIST_ARRAY#
##REQUIRE:ARRAY_NEW,ARRAY_DESTROY,ARRAY_PUSH,ARRAY_POP
::获取列表到数组
::  参数1: 输出变量名
::  返回$: 返回码
:GET_LIST_ARRAY
CALL :ARRAY_NEW "%~1"
FOR /F "tokens=1-4,* usebackq" %%A IN (
    `CMD /V:ON /C "Rsync.EXE %RSYNC_PARAMS% --list-only --no-motd --no-verbose & "Echo.EXE" @ @ @ @ !ERRORLEVEL!" ^| UNIX2DOS.EXE ^| FINDSTR /V /I /X /R /C:".*\."`
) DO (
    CALL :ARRAY_PUSH "%~1" "%%~E"
)
CALL :ARRAY_POP "%~1"
IF NOT "%$%" == "0" CALL :ARRAY_DESTROY "%~1"
EXIT /B %$%
GOTO :EOF
#EOF#
