@echo off

SET CMAKE="C:\Program Files\CMake\bin\cmake.exe"
SET GIT="C:\Program Files\Git\bin\git"
set WINSCP="C:\Program Files (x86)\WinSCP\WinSCP.exe"

SET PROJECTDIR=D:\Libraries\plaYUVer\playuver-scripts\
SET PROJECTBUILDDIR=D:\Libraries\plaYUVer\playuver-build-release
SET PACKAGE_FILE="%PROJECTBUILDDIR%\playuver-*-Windows-amd64"


del %PACKAGE_FILE%.exe
del %PACKAGE_FILE%.zip

cd %PROJECTDIR%\playuver
%GIT% checkout stable
%GIT% pull
cd %PROJECTBUILDDIR%

%CMAKE% -DPACKAGE_NAME=stable -DUPDATE_CHANNEL=stable -DRELEASE_BUILD=ON -DUSE_FERVOR=OFF %PROJECTDIR%
%CMAKE% --build %PROJECTBUILDDIR% --target ALL_BUILD -- /p:Configuration=Release /m:6 >> build_log
IF NOT ERRORLEVEL == 0 (
  echo "ERROR BUILD"
	exit
)
%CMAKE% --build %PROJECTBUILDDIR% --target PACKAGE -- /p:Configuration=Release >> build_log
IF NOT ERRORLEVEL == 0 (
	echo "ERROR PACKAGE"
  exit
)

cd %PROJECTDIR%\playuver
%GIT% checkout master
%GIT% pull
cd %PROJECTBUILDDIR%

%CMAKE% -DPACKAGE_NAME=latest -DUPDATE_CHANNEL=latest -DRELEASE_BUILD=ON %PROJECTDIR%

%CMAKE% --build %PROJECTBUILDDIR% --target ALL_BUILD -- /p:Configuration=Release /m:6 >> build_log
IF NOT ERRORLEVEL == 0 (
	exit
)

%CMAKE% --build %PROJECTBUILDDIR% --target INSTALL -- /p:Configuration=Release >> build_log
IF NOT ERRORLEVEL == 0 (
	exit
)

%CMAKE% --build %PROJECTBUILDDIR% --target PACKAGE -- /p:Configuration=Release >> build_log
IF NOT ERRORLEVEL == 0 (
  echo "ERROR PACKAGE"
	exit
)

echo "Syncing to IT Cluster"

set SCRIPT="D:\Libraries\plaYUVer\ScpScript.tmp"
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
rem Delete temporary script 
REM del %SCRIPT%
