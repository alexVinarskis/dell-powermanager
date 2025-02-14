
:: This script compiles Flutter app as windows application, and packages it to .msi
:: Root folder must contain Flutter application with `.\build\windows`,
::   for the rest, structure of application may change as required

@echo off

set "NAME=Dell Power Manager by VA"
set "PACKAGE=dell-powermanager"

for /f %%a in ('git describe --tags') do (
    set "VER_GIT=%%a"
)
for /f %%a in ('git describe HEAD --tags --abbrev^=0') do (
    set "VERSION_SHORT=%%a"
)

for /f %%A in ('powershell -Command "(Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss')"') do set VER_DATE=%%A

set "VERSION_TAG=%VER_GIT%+%VER_DATE%"
echo Version: %VERSION_TAG%
echo Version short: %VERSION_SHORT%

:: Detect system architecture
:: Only 'master'channel of Flutter currently supports Windows arm64
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set ARCH=x64
    set ARCH_NAME=amd64
) else if "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
    set ARCH=arm64
    set ARCH_NAME=arm64
) else (
    echo Unsupported architecture: %PROCESSOR_ARCHITECTURE%
    exit /b 1
)

:: Bake in app name and version tag to Flutter app
powershell -Command "(Get-Content ./lib/configs/constants.dart) -replace 'applicationName.*', 'applicationName = ''%NAME%'';' | Set-Content ./lib/configs/constants.dart"
powershell -Command "(Get-Content ./lib/configs/constants.dart) -replace 'applicationVersion.*', 'applicationVersion = ''%VERSION_TAG%'';' | Set-Content ./lib/configs/constants.dart"

:: Compile release app
echo: && echo [1/2] Compiling Flutter app...
call flutter build windows --release || exit /b 1

:: Package to .msi
echo: && echo [2/2] Compiling .msi package...
IF EXIST package rmdir /s /q package
mkdir package

copy "resources\icon.ico" "package\"
copy "resources\dell-powermanager.w*" "package\"
copy "resources\dell-powermanager.sln" "package\"
xcopy /E /I /Y "build\windows\%ARCH%\runner\Release" "package\Release"

:: Bake in app name and version to .msi package
powershell -Command "(Get-Content ./package/dell-powermanager.wxs) -replace '1.0.0.0', '%VERSION_SHORT%.0' | Set-Content ./package/dell-powermanager.wxs"
powershell -Command "(Get-Content ./package/dell-powermanager.wxs) -replace 'dell-powermanager', '%NAME%' | Set-Content ./package/dell-powermanager.wxs"

cd package && dotnet build dell-powermanager.wixproj /p:Platform=%ARCH% /clp:ErrorsOnly --configuration Release || exit /b 1
cd ..

copy "package\bin\%ARCH%\Release\dell-powermanager.msi" ".\%PACKAGE%_%VERSION_TAG%_%ARCH_NAME%.msi" || exit /b 1
echo Success! Produced '.\%PACKAGE%_%VERSION_TAG%_%ARCH_NAME%.msi'
rmdir /s/q package
