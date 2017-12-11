::Ŀ¼���ݽű�
::@author FB
::@version 1.07

@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
SET "RETURN=0"

::���������в���
::  ����1: �����ļ�
IF EXIST "%~1" (
  SET "CFG_FILE=%~1"
) ELSE (
  SET "CFG_FILE=%~dpn0.cfg"
)

::��ȡ�����ļ�
FOR %%I IN ("BACKUP_SRC","BACKUP_PATH","BACKUP_FILE","BACKUP_LIMIT") DO SET "%%I="
FOR /F "eol=# tokens=1,* delims== usebackq" %%I IN ("%CFG_FILE%") DO (
  CALL :TRIM "%%I" "VARNAME"
  CALL :TRIM "%%J" "VARDATA"
  SET "!VARNAME!=!VARDATA!"
)

::����·��
IF "_%PROCESSOR_ARCHITECTURE%" == "_AMD64" (
  SET "DISM_EXE=%~dp0\DISMx64\DISM.EXE"
) ELSE (
  SET "DISM_EXE=%~dp0\DISMx86\DISM.EXE"
)

::��鱸��·��
IF NOT EXIST "%BACKUP_PATH%" (
  MKDIR "%BACKUP_PATH%"
  IF NOT EXIST "%BACKUP_PATH%" (
    ECHO.
    ECHO ����·�������ڻ����ô���!
    SET "RETURN=1"
    GOTO :END
  )
)

::���ɱ�����
CALL :FORMAT_DATE "%DATE%" NOW_DATE
SET "BACKUP_NAME=%BACKUP_FILE%_%NOW_DATE%"
SET "NOW_DATE="

::�ж��Ƿ�ִ�й�
FOR /F "tokens=1,2,* delims=^: " %%A IN ('%DISM_EXE% /English /LogPath:"%BACKUP_PATH%\%BACKUP_NAME%_DISM.LOG" /Get-ImageInfo /ImageFile:"%BACKUP_PATH%\%BACKUP_FILE%.wim" ^| FINDSTR "Name .*"') DO IF "_%%~B" == "_%BACKUP_NAME%" (
  ECHO.
  ECHO �����Ѿ�ִ�й�!
  GOTO :END
)

::��ʼ����
CALL :ECHO_DATETIME "========== ��ʼ���� " " ==========" >>"%BACKUP_PATH%\%BACKUP_NAME%.LOG"
IF EXIST "%BACKUP_PATH%\%BACKUP_FILE%.wim" (
  ::��ӵ�WIM�ļ�
  CALL :ECHO_DATETIME "========== ��ӵ�WIM�ļ�(%BACKUP_PATH%\%BACKUP_FILE%.wim) " " ==========" >>"%BACKUP_PATH%\%BACKUP_NAME%.LOG"
  %DISM_EXE% /English /LogPath:"%BACKUP_PATH%\%BACKUP_NAME%_DISM.LOG" /Append-Image /ImageFile:"%BACKUP_PATH%\%BACKUP_FILE%.wim" /CaptureDir:"%BACKUP_SRC%" /Name:"%BACKUP_NAME%" /Description:"Backup [%BACKUP_SRC%] directory." /CheckIntegrity >>"%BACKUP_PATH%\%BACKUP_NAME%.LOG"
) ELSE (
  ::�½�WIM�ļ�
  CALL :ECHO_DATETIME "========== �½���WIM�ļ�(%BACKUP_PATH%\%BACKUP_FILE%.wim) " " ==========" >>"%BACKUP_PATH%\%BACKUP_NAME%.LOG"
  %DISM_EXE% /English /LogPath:"%BACKUP_PATH%\%BACKUP_NAME%_DISM.LOG" /Capture-Image /ImageFile:"%BACKUP_PATH%\%BACKUP_FILE%.wim" /CaptureDir:"%BACKUP_SRC%" /Name:"%BACKUP_NAME%" /Description:"Backup [%BACKUP_SRC%] directory." /Compress:max /CheckIntegrity >>"%BACKUP_PATH%\%BACKUP_NAME%.LOG"
)
::�������ʧ��
IF NOT "_%ERRORLEVEL%" == "_0" (
  CALL :ECHO_DATETIME "========== ����ʧ�� " " ==========" >>"%BACKUP_PATH%\%BACKUP_NAME%.LOG"
  RENAME "%BACKUP_PATH%\%BACKUP_NAME%.LOG" "%BACKUP_NAME%_ERROR.LOG"
  SET "RETURN=1"
  GOTO :END
) ELSE (
  CALL :ECHO_DATETIME "========== ���ݳɹ� " " ==========" >>"%BACKUP_PATH%\%BACKUP_NAME%.LOG"
)

::������ڱ���
CALL :ECHO_DATETIME "========== ��ʼ������ڱ��� " " ==========" >>"%BACKUP_PATH%\%BACKUP_NAME%.LOG"
::��ȡ��������
SET "OVERDUE_COUNT=0"
FOR /F "tokens=1,2,* delims=^: " %%A IN ('%DISM_EXE% /English /LogPath:"%BACKUP_PATH%\%BACKUP_NAME%_DISM.LOG" /Get-ImageInfo /ImageFile:"%BACKUP_PATH%\%BACKUP_FILE%.wim" ^| FINDSTR "Name .*"') DO SET /A "OVERDUE_COUNT=!OVERDUE_COUNT!+1"
::�����������
SET /A "OVERDUE_COUNT=%OVERDUE_COUNT%-%BACKUP_LIMIT%"
::�������
FOR /L %%I IN (1,1,%OVERDUE_COUNT%) DO (
  ::��ȡ������־�ļ���
  FOR /F "tokens=1,2,* delims=^: " %%A IN ('%DISM_EXE% /English /LogPath:"%BACKUP_PATH%\%BACKUP_NAME%_DISM.LOG" /Get-ImageInfo /ImageFile:"%BACKUP_PATH%\%BACKUP_FILE%.wim" /Index:1 ^| FINDSTR "Name .*"') DO SET "OVERDUE_NAME=%%~B"
  ::ɾ����־�ļ�
  CALL :ECHO_DATETIME "========== ɾ����־�ļ�(!OVERDUE_NAME!*.LOG) " " ==========" >>"%BACKUP_PATH%\%BACKUP_NAME%.LOG"
  DEL /F /Q "%BACKUP_PATH%\!OVERDUE_NAME!*.LOG" 1>>"%BACKUP_PATH%\%BACKUP_NAME%.LOG" 2>>&1
  ::ɾ������
  CALL :ECHO_DATETIME "========== ɾ������(!OVERDUE_NAME!) " " ==========" >>"%BACKUP_PATH%\%BACKUP_NAME%.LOG"
  %DISM_EXE% /English /LogPath:"%BACKUP_PATH%\%BACKUP_NAME%_DISM.LOG" /Delete-Image /ImageFile:"%BACKUP_PATH%\%BACKUP_FILE%.wim" /Index:1 /CheckIntegrity >>"%BACKUP_PATH%\%BACKUP_NAME%.LOG"
)
SET "OVERDUE_NAME="
SET "OVERDUE_COUNT="

::���ݲ�������
CALL :ECHO_DATETIME "========== ���ݲ������� " " ==========" >>"%BACKUP_PATH%\%BACKUP_NAME%.LOG"
GOTO :END

::ͳһ���ڸ�ʽ�ַ���
::  ����1: �������ڸ�ʽ(yyyy MM dd)
::  ����2: ���������(�����������Ļ)
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

::���ɵ�ǰʱ��
::  ����1: ǰ׺����
::  ����2: ��׺����
:ECHO_DATETIME
@ECHO %~1 %DATE% %TIME% %~2
GOTO :EOF

::ȥ�ո�
::  ����1: Ŀ���ַ���
::  ����2: �����������(��ѡ,ֱ���������Ļ)
:TRIM
CALL :TRIM_TO_VAR %~1
IF "_%~2" == "_" (
  ECHO %TRIMED_STRING%
) ELSE (
  SET "%~2=%TRIMED_STRING%"
)
SET "TRIMED_STRING="
GOTO :EOF

::ȥ�ո񵽹̶�����TRIMED_STRING
::  ����: Ŀ���ַ���
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
