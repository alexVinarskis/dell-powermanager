#!/bin/bash

# This script compiles Flutter app as linux application, and packages it to .deb
# Root folder must contain Flutter application with `./build/linux`,
#   for the rest, structure of application may change as required

# exit when any command fails
set -e

PACKAGE="dell-powermanager"
NAME="Dell Power Manager by VA"

PATH_EXEC="/usr/local/bin/$PACKAGE"
PATH_CCTK="/opt/dell/dcc/cctk"
ICON_PATH="/opt/$PACKAGE/icon"
APP_PATH="/opt/$PACKAGE"
APP_DIR="./package$APP_PATH"
DEB_DIR="./package/DEBIAN"
VERSION=$(git describe --tags)+$(date '+%Y%m%d-%H%M%S')
ARCHITECTURE=$(dpkg --print-architecture)
BUILD_PATH="build/linux/$([[ $(dpkg --print-architecture) == 'arm64' ]] && echo 'arm64' || echo 'x64')/release/bundle"

# Bake in app name and version tag
sed -i "s|applicationName".*"|applicationName = '${NAME}';|g"                   ./lib/configs/constants.dart
sed -i "s|applicationPackageName".*"|applicationPackageName = '${PACKAGE}';|g"  ./lib/configs/constants.dart
sed -i "s|applicationVersion".*"|applicationVersion = '${VERSION}';|g"          ./lib/configs/constants.dart

rm -rf ./package
mkdir -p "$APP_DIR"
mkdir -p "$DEB_DIR"
mkdir -p ./package/usr/local/bin
mkdir -p ./package/etc/sudoers.d
mkdir -p ./package/usr/local/share/applications/

# Compile release app
flutter clean
flutter build linux --release

# Build application archive
(
    cd "$BUILD_PATH"
    tar -cJf "../../../../../${PACKAGE}_${VERSION}_${ARCHITECTURE}".tar.xz *
)

# Copy application files
cp -r "$BUILD_PATH"/*                       "$APP_DIR"
cp ./resources/icon.png                     ./package/"$ICON_PATH"
cp ./resources/dell-powermanager.desktop    ./package/usr/local/share/applications/

sed -i "s|{VERSION}|${VERSION}|g"           ./package/usr/local/share/applications/dell-powermanager.desktop
sed -i "s|{PACKAGE}|${PACKAGE}|g"           ./package/usr/local/share/applications/dell-powermanager.desktop
sed -i "s|{PATH_ICON}|${ICON_PATH}|g"       ./package/usr/local/share/applications/dell-powermanager.desktop
sed -i "s|{NAME}|${NAME}|g"                 ./package/usr/local/share/applications/dell-powermanager.desktop

PRIORITY="standard"
MAINTAINER="alexVinarskis <alex.vinarskis@gmail.com>"
HOMEPAGE="https://github.com/alexVinarskis/dell-powermanager"
DEPENDS="libgtk-3-0, libblkid1, liblzma5, curl, apt, tar, pkexec, bash, libsecret-1-0"
DESCRIPTION="Cross-Platform Dell Power Manager re-implementation in Flutter"

# Create control file of .deb
touch "$DEB_DIR"/control
echo "Package: ${PACKAGE}"                  >> "$DEB_DIR"/control
echo "Version: ${VERSION}"                  >> "$DEB_DIR"/control
echo "Architecture: ${ARCHITECTURE}"        >> "$DEB_DIR"/control
echo "Maintainer: ${MAINTAINER}"            >> "$DEB_DIR"/control
echo "Priority: ${PRIORITY}"                >> "$DEB_DIR"/control
echo "Description: ${DESCRIPTION}"          >> "$DEB_DIR"/control
echo "Depends: ${DEPENDS}"                  >> "$DEB_DIR"/control
echo "Homepage: ${HOMEPAGE}"                >> "$DEB_DIR"/control

# Create postinstall file of .deb
touch "$DEB_DIR"/postinst && chmod 755 "$DEB_DIR"/postinst
echo "ln -s $APP_PATH/dell_powermanager $PATH_EXEC" >> "$DEB_DIR"/postinst

# Create preremove file of .deb
touch "$DEB_DIR"/prerm && chmod 755 "$DEB_DIR"/prerm
echo "sudo rm -f $PATH_EXEC" >> "$DEB_DIR"/prerm

# Package
dpkg-deb --build --root-owner-group ./package
mv ./package.deb ./${PACKAGE}_${VERSION}_${ARCHITECTURE}.deb
echo -e "Success!\nProduced './${PACKAGE}_${VERSION}_${ARCHITECTURE}.deb'\nProduced './${PACKAGE}_${VERSION}_${ARCHITECTURE}.tar.xz'"
rm -rf ./package
