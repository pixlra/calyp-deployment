@echo off

SET CMAKE="C:\Program Files\CMake\bin\cmake.exe"
SET GIT="C:\Program Files\Git\bin\git"
set WINSCP="C:\Program Files (x86)\WinSCP\WinSCP.exe"

CALL :NORMALIZEPATH "..\cmake-helper"
SET PROJECTDIR=%RETVAL%

CALL :NORMALIZEPATH "..\..\calyp-build-release"
SET PROJECTBUILDDIR=%RETVAL%

SET PACKAGE_FILE="%PROJECTBUILDDIR%\calyp-*-Windows-amd64"

del %PACKAGE_FILE%.exe
del %PACKAGE_FILE%.zip

REM cd %PROJECTDIR%\calyp
REM %GIT% checkout stable
REM %GIT% pull
REM cd %PROJECTBUILDDIR%

REM %CMAKE% -DPACKAGE_NAME=stable -DUPDATE_CHANNEL=stable -DRELEASE_BUILD=ON -DUSE_FERVOR=OFF %PROJECTDIR%
REM %CMAKE% --build %PROJECTBUILDDIR% --target ALL_BUILD -- /p:Configuration=Release /m:6 >> build_log
REM IF NOT ERRORLEVEL == 0 (
  REM echo "ERROR BUILD"
	REM exit
REM )
REM %CMAKE% --build %PROJECTBUILDDIR% --target PACKAGE -- /p:Configuration=Release >> build_log
REM IF NOT ERRORLEVEL == 0 (
	REM echo "ERROR PACKAGE"
  REM exit
REM )

cd %PROJECTDIR%\calyp
%GIT% checkout master
%GIT% pull
cd %PROJECTBUILDDIR%

%CMAKE% -DPACKAGE_NAME=latest -DUPDATE_CHANNEL=latest -DRELEASE_BUILD=ON %PROJECTDIR%
IF NOT ERRORLEVEL == 0 (
	echo "ERROR CMAKE"
	exit
)
%CMAKE% --build %PROJECTBUILDDIR% --target ALL_BUILD -- /p:Configuration=Release /m:6 >> build_log
IF NOT ERRORLEVEL == 0 (
	echo "ERROR BUILD"
	exit
)
%CMAKE% --build %PROJECTBUILDDIR% --target INSTALL -- /p:Configuration=Release >> build_log
IF NOT ERRORLEVEL == 0 (
	echo "ERROR INSTALL"
	exit
)
%CMAKE% --build %PROJECTBUILDDIR% --target PACKAGE -- /p:Configuration=Release >> build_log
IF NOT ERRORLEVEL == 0 (
  echo "ERROR PACKAGE"
	exit
)

REM Sending packages to IT Cluster
cd %PROJECTDIR%

set SCRIPT="ScpScript.tmp"
set REMOTEPATH="/nfs/data/share/PlaYUVerProject/windows"

rem Generate temporary script to upload %1
echo option batch abort > %SCRIPT%
echo option confirm off >> %SCRIPT%
echo open jcarreira.it@itcluster >> %SCRIPT%
echo cd %REMOTEPATH%  >> %SCRIPT%
echo put %PACKAGE_FILE%.zip >> %SCRIPT%
echo put %PACKAGE_FILE%.exe >> %SCRIPT%
echo exit >> %SCRIPT%
rem Execute script
%WINSCP% /script=%SCRIPT%
IF NOT ERRORLEVEL == 0 (
	echo "ERROR SCP"
	exit
)
del %SCRIPT%

:: ========== FUNCTIONS ==========
EXIT /B

:NORMALIZEPATH
  SET RETVAL=%~dpfn1
  EXIT /B
