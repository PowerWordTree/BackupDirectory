::�����ļ��ӳ���
::@author FB
::@version 0.1

@ECHO OFF
CALL :%*
GOTO :EOF

:TRIM
CALL Common.CMD TRIM %*
GOTO :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

#CLEAN_VARS#
::��������
::  ����: ������(֧�ֶ��)
:CLEAN_VARS
FOR %%I IN (%*) DO SET "%%I="
GOTO :EOF
#EOF#

#READ_CONF#
##REQUIRE:TRIM
::��ȡ�����ļ�
::  ����: �����ļ���
:READ_CONF
FOR /F "eol=# tokens=1,* usebackq delims==" %%I IN (`TYPE "%~1" 2^>NUL`) DO (
  CALL :TRIM "%%~I"
  SET  "$NAME=!$!"
  CALL :TRIM "%%~J"
  SET "!$NAME!=!$!"
)
SET "$NAME="
GOTO :EOF
#EOF#