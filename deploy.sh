#!/bin/bash

ver=$(wget https://api.github.com/repos/notepad-plus-plus/notepad-plus-plus/releases -qO - 2>&1 | grep "Notepad++ " | sed s'|"| |g' | awk '{print $5}' | head -n1)
wget https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v$(echo $ver | grep -o -E '[0-9]+' | head -1 | sed -e 's/^0\+//')/npp.${ver}.Installer.x64.exe &> /dev/null
7z x -aos "npp.$ver.Installer.x64.exe" -x'!change.log' -x'!doLocalConf.xml' -x'!LICENSE' -x'!NppShell_06.dll' -x'!readme.txt' -x'!userDefinedLang-markdown.default.modern.xml' -o"npp-stable/usr/share/notepad-plus-plus"
# winedata
appdir="npp-stable/usr/share/notepad-plus-plus"
mkdir -p "npp-stable/winedata/Application Data/Notepad++" && mkdir -p "npp-stable/usr/share/notepad-plus-plus/plugins/Config"
cp -R $appdir/'$_14_'/* "npp-stable/winedata/Application Data/Notepad++";cp -R $appdir/'$_15_'/* "npp-stable/usr/share/notepad-plus-plus/plugins";cp -R $appdir/'$_17_'/* "npp-stable/usr/share/notepad-plus-plus/plugins/Config"
find $appdir/'$PLUGINSDIR' -type f -name '*.xml' -print0 | while read -d $'\0' file; do cp -v "$file" $appdir/localization/ &>/dev/null; done
rm -R $appdir/'$_14_';rm -R $appdir/'$_15_';rm -R $appdir/'$_17_';rm -R $appdir/'$PLUGINSDIR';
find "npp-stable/usr" -type d -execdir chmod 755 {} + && find "npp-stable/winedata" -type d -execdir chmod 755 "{}" +
rm ./*.exe

mkdir -p npp-stable/usr/bin ; cp notepad-plus-plus.desktop npp-stable ; cp AppRun npp-stable ; sed -i -e 's|progVer=|progVer='"$ver"'|g' npp-stable/AppRun

# Convert and copy icon which is needed for desktop integration into place:
wget https://github.com/mmtrt/notepad-plus-plus/raw/master/snap/local/src/notepad-plus-plus.png -O notepad-plus-plus.png &>/dev/null
for width in 8 16 22 24 32 36 42 48 64 72 96 128 192 256; do
    dir=icons/hicolor/${width}x${width}/apps
    mkdir -p $dir
    convert notepad-plus-plus.png -resize ${width}x${width} $dir/notepad-plus-plus.png
done

cp -r icons npp-stable/usr/share ; cp notepad-plus-plus.png npp-stable

wget -c "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
chmod +x ./appimagetool-x86_64.AppImage
./appimagetool-x86_64.AppImage --appimage-extract

export ARCH=x86_64; squashfs-root/AppRun -v ./npp-stable -u "gh-releases-zsync|mmtrt|notepad-plus-plus_AppImage|stable|notepad*.AppImage.zsync" notepad-plus-plus_"${ver}"-${ARCH}.AppImage
