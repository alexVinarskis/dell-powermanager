
: This script compiles Flutter app as windows application, and packages it to .msi
: Root folder must contain Flutter application with `./build/windows`,
:   for the rest, structure of application may change as required

@echo off

set "NAME=Dell Power Manager by VA"
set "PACKAGE=dell-powermanager"

for /f %%a in ('git describe --tags') do (
    set "VER_GIT=%%a"
)
set "VER_DATE=%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%-%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%"
set "VERSION=%VER_GIT%+%VER_DATE%"

: Bake in app name and version tag
sed -i "s|applicationName".*"|applicationName = '%NAME%';|g"            ./lib/configs/constants.dart
sed -i "s|applicationVersion".*"|applicationVersion = '%VERSION%';|g"   ./lib/configs/constants.dart

: Compile release app
flutter build windows --release

: ToDo... package to .msi or .exe
