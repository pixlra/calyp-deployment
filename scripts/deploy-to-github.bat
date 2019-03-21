dir /P /B "calyp-*.zip" > tmp_filename 
set /p source= < tmp_filename
copy %source% calyp-latest.zip
del tmp_filename 
dir /P /B "calyp-*.exe" > tmp_filename 
set /p source= < tmp_filename
copy %source% calyp-latest.exe
del tmp_filename 

git clone -b master --single-branch https://github.com/pixlra/calyp-releases.git --depth 1
cd calyp-releases
git rm --ignore-unmatch autoupdate\win\*
git rm --ignore-unmatch installers\win\*
xcopy /E ..\install\* autoupdate\win\. /I/Y
xcopy ..\calyp-latest.zip installers\win\ /I/Y
xcopy ..\calyp-latest.exe installers\win\ /I/Y
git add autoupdate\win\*
git add installers\win\*
git status
git commit -a --allow-empty -m "Appveyor build %APPVEYOR_BUILD_NUMBER%, %APPVEYOR_BUILD_VERSION% based on %APPVEYOR_REPO_COMMIT%"
git push -f
