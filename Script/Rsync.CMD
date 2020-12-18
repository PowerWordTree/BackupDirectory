::Rsync�ӳ���
::@author FB
::@version 0.1

@ECHO OFF
CALL :%*
GOTO :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

#PARAM_SET#
::�滻����
::  ����N: ����
:PARAM_SET
SET "RSYNC_PARAMS=%*"
GOTO :EOF
#EOF#

#PARAM_ADD#
::���Ӳ���
::  ����N: Ҫ���ӵĲ���
:PARAM_ADD
SET "RSYNC_PARAMS=%RSYNC_PARAMS% %*"
GOTO :EOF
#EOF#

#RUN#
::����
::  ����1: Դ·��
::  ����2: Ŀ��·��
:RUN
RSYNC.EXE %RSYNC_PARAMS% %1 %2
GOTO :EOF
#EOF#

#RUN#
::ģ������
::  ����1: Դ·��
::  ����2: Ŀ��·��
:DRY_RUN
RSYNC.EXE %RSYNC_PARAMS% --dry-run %1 %2
GOTO :EOF
#EOF#

#RUN#
::�г��ļ��б�
::  ����1: Դ·��
:LIST
RSYNC.EXE %RSYNC_PARAMS% --list-only %1
GOTO :EOF
#EOF#