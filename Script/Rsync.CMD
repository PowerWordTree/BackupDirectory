::Rsync子程序
::@author FB
::@version 0.1

@ECHO OFF
CALL :%*
GOTO :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

##Bin:Rsync.EXE,Echo.EXE,Unix2dos.EXE##
##Script:Common.CMD,Array.CMD,Map.CMD##

::设置参数
::  参数N: 参数
:PARAM_SET
SET "RSYNC_PARAMS=%*"
GOTO :EOF

::添加参数
::  参数N: 要添加的参数
:PARAM_ADD
SET "RSYNC_PARAMS=%RSYNC_PARAMS% %*"
GOTO :EOF

::运行
:RUN
Rsync.EXE %RSYNC_PARAMS%
GOTO :EOF

::模拟运行
:DRY_RUN
Rsync.EXE --dry-run %RSYNC_PARAMS%
GOTO :EOF

::获取列表
:LIST
Rsync.EXE --list-only %RSYNC_PARAMS%
GOTO :EOF

::执行并输出到Array
::  参数1: 输出变量名
::  返回$: 返回码
:GET_TRANSFER_ARRAY
CALL Array.CMD NEW "%~1"
FOR /F "tokens=* usebackq" %%A IN (
    `CMD /V:ON /C "Rsync.EXE %RSYNC_PARAMS% --no-motd --verbose & "Echo.EXE" !ERRORLEVEL!" ^| Unix2dos.EXE ^| FINDSTR /V /I /X /R /C:"building file list .*" /C:"sending incremental file list" /C:"created directory .*" /C:"\./" /C:"sent .* received .*" /C:"total size is .* speedup is .*"`
) DO (
    CALL Array.CMD NEW "%~1" "%%~A"
)
CALL Array.CMD POP "%~1"
IF NOT "%$%" == "0" CALL Array.CMD DESTROY "%~1"
EXIT /B %$%
GOTO :EOF

::执行并获取状态到Map
::  参数1: 输出变量名
::  返回$: 返回码
:GET_STATS_MAP
CALL Map.CMD NEW "%~1"
FOR /F "tokens=1,* usebackq delims=:" %%A IN (
    `CMD /V:ON /C "Rsync.EXE %RSYNC_PARAMS% --stats --no-motd --no-verbose & "Echo.EXE" ERRORLEVEL:!ERRORLEVEL!" ^| Unix2dos.EXE ^| FINDSTR ":"`
) DO (
    CALL Common.CMD TRIM "%%~B"
    CALL Map.CMD PUT "%~1" "%%~A" "%%$%%"
)
CALL Map.CMD REMOVE "%~1" "ERRORLEVEL"
IF NOT "%$%" == "0" CALL Map.CMD DESTROY "%~1"
EXIT /B %$%
GOTO :EOF

::获取列表到Array
::  参数1: 输出变量名
::  返回$: 返回码
:GET_LIST_ARRAY
CALL Array.CMD NEW "%~1"
FOR /F "tokens=1-4,* usebackq" %%A IN (
    `CMD /V:ON /C "Rsync.EXE %RSYNC_PARAMS% --list-only --no-motd --no-verbose & "Echo.EXE" @ @ @ @ !ERRORLEVEL!" ^| Unix2dos.EXE ^| FINDSTR /V /I /X /R /C:".*\."`
) DO (
    CALL Array.CMD PUSH "%~1" "%%~E"
)
CALL Array.CMD POP "%~1"
IF NOT "%$%" == "0" CALL Array.CMD DESTROY "%~1"
EXIT /B %$%
GOTO :EOF
