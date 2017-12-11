::目录备份脚本
::@author FB
::@version 1.07

@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
SET "RETURN=0"

::处理命令行参数
::  参数1: 配置文件
IF EXIST "%~1" (
  SET "CFG_FILE=%~1"
) ELSE (
  SET "CFG_FILE=%~dpn0.cfg"
)

::读取配置文件
FOR %%I IN ("BACKUP_SRC","BACKUP_PATH","BACKUP_FILE","BACKUP_LIMIT") DO SET "%%I="
FOR /F "eol=# tokens=1,* delims== usebackq" %%I IN ("%CFG_FILE%") DO (
  CALL :TRIM "%%I" "VARNAME"
  CALL :TRIM "%%J" "VARDATA"
  SET "!VARNAME!=!VARDATA!"
)

::处理路径
IF "_%PROCESSOR_ARCHITECTURE%" == "_AMD64" (
  SET "DISM_EXE=%~dp0\DISMx64\DISM.EXE"
) ELSE (
  SET "DISM_EXE=%~dp0\DISMx86\DISM.EXE"
)

::检查备份路径
IF NOT EXIST "%BACKUP_PATH%" (
  MKDIR "%BACKUP_PATH%"
  IF NOT EXIST "%BACKUP_PATH%" (
    ECHO.
    ECHO 备份路径不存在或设置错误!
    SET "RETURN=1"
    GOTO :END
  )
)

::生成备份名
CALL :FORMAT_DATE "%DATE%" NOW_DATE
SET "BACKUP_NAME=%BACKUP_FILE%_%NOW_DATE%"
SET "NOW_DATE="

::判断是否执行过
FOR /F "tokens=1,2,* delims=^: " %%A IN ('%DISM_EXE% /English /LogPath:"%BACKUP_PATH%\%BACKUP_NAME%_DISM.LOG" /Get-ImageInfo /ImageFile:"%BACKUP_PATH%\%BACKUP_FILE%.wim" ^| FINDSTR "Name .*"') DO IF "_%%~B" == "_%BACKUP_NAME%" (
  ECHO.
  ECHO 今天已经执行过!
  GOTO :END
)

::开始备份
CALL :ECHO_DATETIME "========== 开始备份 " " ==========" >>"%BACKUP_PATH%\%BACKUP_NAME%.LOG"
IF EXIST "%BACKUP_PATH%\%BACKUP_FILE%.wim" (
  ::添加到WIM文件
  CALL :ECHO_DATETIME "========== 添加到WIM文件(%BACKUP_PATH%\%BACKUP_FILE%.wim) " " ==========" >>"%BACKUP_PATH%\%BACKUP_NAME%.LOG"
  %DISM_EXE% /English /LogPath:"%BACKUP_PATH%\%BACKUP_NAME%_DISM.LOG" /Append-Image /ImageFile:"%BACKUP_PATH%\%BACKUP_FILE%.wim" /CaptureDir:"%BACKUP_SRC%" /Name:"%BACKUP_NAME%" /Description:"Backup [%BACKUP_SRC%] directory." /CheckIntegrity >>"%BACKUP_PATH%\%BACKUP_NAME%.LOG"
) ELSE (
  ::新建WIM文件
  CALL :ECHO_DATETIME "========== 新建到WIM文件(%BACKUP_PATH%\%BACKUP_FILE%.wim) " " ==========" >>"%BACKUP_PATH%\%BACKUP_NAME%.LOG"
  %DISM_EXE% /English /LogPath:"%BACKUP_PATH%\%BACKUP_NAME%_DISM.LOG" /Capture-Image /ImageFile:"%BACKUP_PATH%\%BACKUP_FILE%.wim" /CaptureDir:"%BACKUP_SRC%" /Name:"%BACKUP_NAME%" /Description:"Backup [%BACKUP_SRC%] directory." /Compress:max /CheckIntegrity >>"%BACKUP_PATH%\%BACKUP_NAME%.LOG"
)
::如果备份失败
IF NOT "_%ERRORLEVEL%" == "_0" (
  CALL :ECHO_DATETIME "========== 备份失败 " " ==========" >>"%BACKUP_PATH%\%BACKUP_NAME%.LOG"
  RENAME "%BACKUP_PATH%\%BACKUP_NAME%.LOG" "%BACKUP_NAME%_ERROR.LOG"
  SET "RETURN=1"
  GOTO :END
) ELSE (
  CALL :ECHO_DATETIME "========== 备份成功 " " ==========" >>"%BACKUP_PATH%\%BACKUP_NAME%.LOG"
)

::清理过期备份
CALL :ECHO_DATETIME "========== 开始清理过期备份 " " ==========" >>"%BACKUP_PATH%\%BACKUP_NAME%.LOG"
::获取备份数量
SET "OVERDUE_COUNT=0"
FOR /F "tokens=1,2,* delims=^: " %%A IN ('%DISM_EXE% /English /LogPath:"%BACKUP_PATH%\%BACKUP_NAME%_DISM.LOG" /Get-ImageInfo /ImageFile:"%BACKUP_PATH%\%BACKUP_FILE%.wim" ^| FINDSTR "Name .*"') DO SET /A "OVERDUE_COUNT=!OVERDUE_COUNT!+1"
::计算过期数量
SET /A "OVERDUE_COUNT=%OVERDUE_COUNT%-%BACKUP_LIMIT%"
::清理过期
FOR /L %%I IN (1,1,%OVERDUE_COUNT%) DO (
  ::获取过期日志文件名
  FOR /F "tokens=1,2,* delims=^: " %%A IN ('%DISM_EXE% /English /LogPath:"%BACKUP_PATH%\%BACKUP_NAME%_DISM.LOG" /Get-ImageInfo /ImageFile:"%BACKUP_PATH%\%BACKUP_FILE%.wim" /Index:1 ^| FINDSTR "Name .*"') DO SET "OVERDUE_NAME=%%~B"
  ::删除日志文件
  CALL :ECHO_DATETIME "========== 删除日志文件(!OVERDUE_NAME!*.LOG) " " ==========" >>"%BACKUP_PATH%\%BACKUP_NAME%.LOG"
  DEL /F /Q "%BACKUP_PATH%\!OVERDUE_NAME!*.LOG" 1>>"%BACKUP_PATH%\%BACKUP_NAME%.LOG" 2>>&1
  ::删除备份
  CALL :ECHO_DATETIME "========== 删除镜像(!OVERDUE_NAME!) " " ==========" >>"%BACKUP_PATH%\%BACKUP_NAME%.LOG"
  %DISM_EXE% /English /LogPath:"%BACKUP_PATH%\%BACKUP_NAME%_DISM.LOG" /Delete-Image /ImageFile:"%BACKUP_PATH%\%BACKUP_FILE%.wim" /Index:1 /CheckIntegrity >>"%BACKUP_PATH%\%BACKUP_NAME%.LOG"
)
SET "OVERDUE_NAME="
SET "OVERDUE_COUNT="

::备份操作结束
CALL :ECHO_DATETIME "========== 备份操作结束 " " ==========" >>"%BACKUP_PATH%\%BACKUP_NAME%.LOG"
GOTO :END

::统一日期格式字符串
::  参数1: 输入日期格式(yyyy MM dd)
::  参数2: 输出到变量(否则输出到屏幕)
:FORMAT_DATE
SET "CU_DATE=%~1"
IF "_%CU_DATE%" == "_" SET "CU_DATE=%DATE%"
FOR /F "tokens=1,2,3,* delims=/.-\ " %%A IN ("%CU_DATE%") DO (
  IF "_%~2" == "_" (
    ECHO %%A-%%B-%%C
  ) ELSE (
    SET "%~2=%%A-%%B-%%C"
  )
)
SET "CU_DATE="
GOTO :EOF

::生成当前时间
::  参数1: 前缀文字
::  参数2: 后缀文字
:ECHO_DATETIME
@ECHO %~1 %DATE% %TIME% %~2
GOTO :EOF

::去空格
::  参数1: 目标字符串
::  参数2: 输出到变量名(可选,直接输出到屏幕)
:TRIM
CALL :TRIM_TO_VAR %~1
IF "_%~2" == "_" (
  ECHO %TRIMED_STRING%
) ELSE (
  SET "%~2=%TRIMED_STRING%"
)
SET "TRIMED_STRING="
GOTO :EOF

::去空格到固定变量TRIMED_STRING
::  参数: 目标字符串
:TRIM_TO_VAR
SET "TRIMED_STRING=%*"
GOTO :EOF

:END
SET "BACKUP_SRC="
SET "BACKUP_PATH="
SET "BACKUP_FILE="
SET "BACKUP_LIMIT="
SET "BACKUP_NAME="

EXIT /B %RETURN%
