
: This script compiles Flutter app as windows application, and packages it to .msi
: Root folder must contain Flutter application with `./build/windows`,
:   for the rest, structure of application may change as required

@echo off

set "NAME=Dell Power Manager by VA"
set "PACKAGE=dell-powermanager"

for /f %%a in ('git describe --tags') do (
    set "VER_GIT=%%a"
)
for /f %%a in ('git describe HEAD --tags --abbrev^=0') do (
    set "VERSION_SHORT=%%a"
)

for /f %%x in ('wmic path win32_utctime get /format:list ^| findstr "="') do set %%x
set Month=00%Month%
set Day=00%Day%
set Hour=00%Hour%
set Minute=00%Minute%
set Second=00%Second%

set "VER_DATE=%Year%%Month:~-2%%Day:~-2%-%Hour:~-2%%Minute:~-2%%Second:~-2%"
set "VERSION_TAG=%VER_GIT%+%VER_DATE%"
echo Version: %VERSION_TAG%
echo Version short: %VERSION_SHORT%

: Bake in app name and version tag to Flutter app
sed -i "s|applicationName".*"|applicationName = '%NAME%';|g"                ./lib/configs/constants.dart
sed -i "s|applicationVersion".*"|applicationVersion = '%VERSION_TAG%';|g"   ./lib/configs/constants.dart

: Compile release app
echo: && echo [1/2] Compiling Flutter app...
call flutter build windows --release || exit 1

: Package to .msi
echo: && echo [2/2] Compiling .msi package...
IF EXIST package rmdir /s /q package
mkdir package

cp resources/icon.ico package/
cp resources/dell-powermanager.w* resources/dell-powermanager.sln package/
cp -r build/windows/x64/runner/Release package/

: Bake in app name and version to .msi package
sed -i "s|1.0.0.0|%VERSION_SHORT%.0|g"                                      ./package/dell-powermanager.wxs
sed -i "s|dell-powermanager|%NAME%|g"                                       ./package/dell-powermanager.wxs

cd package && dotnet build dell-powermanager.wixproj /p:Platform=x64 /clp:ErrorsOnly --configuration Release || exit 1
cd ..

cp package/bin/x64/Release/dell-powermanager.msi ./%PACKAGE%_%VERSION_TAG%_amd64.msi || exit 1
echo Success! Produced './%PACKAGE%_%VERSION_TAG%_amd64.msi'
rmdir /s/q package
