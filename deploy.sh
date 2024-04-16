#!/bin/bash

npps () {

# Download icon:
wget -q https://github.com/mmtrt/notepad-plus-plus/raw/master/snap/local/src/notepad-plus-plus.png -O notepad-plus-plus.png

wget -q "https://github.com/AppImageCrafters/appimage-builder/releases/download/v1.0.3/appimage-builder-1.0.3-x86_64.AppImage" -O builder ; chmod +x builder ; ./builder --appimage-extract &>/dev/null

# add custom mksquashfs
wget -q "https://github.com/mmtrt/WINE_AppImage/raw/master/runtime/mksquashfs" -O squashfs-root/usr/bin/mksquashfs

# force zstd format in appimagebuilder for appimages
rm builder ; sed -i 's|xz|zstd|' squashfs-root/usr/lib/python3.8/site-packages/appimagebuilder/modules/prime/appimage_primer.py

# Download 7zip cli upstream
wget -qO- https://www.7-zip.org/a/$(wget -qO- https://www.7-zip.org | grep -Eo -m2 '7z.*.exe"' | tail -1 | sed 's/.exe"/-linux-x64.tar.xz/') | tar -J -xvf - 7zz

# Add static appimage runtime
mkdir -p appimage-build/prime
wget -q "https://github.com/mmtrt/WINE_AppImage/raw/master/runtime/runtime-x86_64" -O appimage-build/prime/runtime-x86_64

ver=$(wget https://github.com/notepad-plus-plus/notepad-plus-plus/releases -qO - 2>&1 | grep -Eo ".*.x6" | grep npp | grep -Po "(\d+\.)+\d+" | head -n1)
wget -q https://github.com/$(wget -qO- https://github.com/notepad-plus-plus/notepad-plus-plus/releases | grep download/ | cut -d '"' -f2 | sed -n 5p)
./7zz x -aos "npp.$ver.Installer.exe" -x'!change.log' -x'!doLocalConf.xml' -x'!LICENSE' -x'!NppShell_06.dll' -x'!readme.txt' -x'!userDefinedLang-markdown.default.modern.xml' -o"npp-stable/usr/share/notepad-plus-plus" &>/dev/null
# winedata
appdir="npp-stable/usr/share/notepad-plus-plus"
mkdir -p "npp-stable/winedata/Application Data/Notepad++" && mkdir -p "npp-stable/usr/share/notepad-plus-plus/plugins/Config"
mv $appdir/notepad++.exe $appdir/notepad-plus-plus.exe
cp -R $appdir/'$_14_'/* "npp-stable/winedata/Application Data/Notepad++";cp -R $appdir/'$_15_'/* "npp-stable/usr/share/notepad-plus-plus/plugins";cp -R $appdir/'$_17_'/* "npp-stable/usr/share/notepad-plus-plus/plugins/Config"
find $appdir/'$PLUGINSDIR' -type f -name '*.xml' -print0 | while read -d $'\0' file; do cp -v "$file" $appdir/localization/ &>/dev/null; done
rm -R $appdir/'$_14_';rm -R $appdir/'$_15_';rm -R $appdir/'$_17_';rm -R $appdir/'$PLUGINSDIR';
find "npp-stable/usr" -type d -execdir chmod 755 {} + && find "npp-stable/winedata" -type d -execdir chmod 755 "{}" +
rm ./*.exe

mkdir -p npp-stable/usr/bin ; mkdir -p npp-stable/usr/share/icons; cp notepad-plus-plus.desktop npp-stable ; cp wrapper npp-stable ; sed -i -e 's|progVer=|progVer='"$ver"'|g' npp-stable/wrapper ; cp notepad-plus-plus.png npp-stable/usr/share/icons

mkdir -p AppDir/winedata ; cp -r "npp-stable/"* AppDir

./squashfs-root/AppRun --recipe npp.yml
}

nppswp () {

export WINEDLLOVERRIDES="mscoree,mshtml="
export WINEARCH="win32"
export WINEPREFIX="/home/runner/work/notepad-plus-plus_AppImage/notepad-plus-plus_AppImage/AppDir/winedata/.wine"
export WINEDEBUG="-all"

wget -q "https://github.com/mmtrt/sommelier-core/raw/tmp/themes/light/light.msstyles" -P $WINEPREFIX/drive_c/windows/resources/themes/light

wget -q https://github.com/mmtrt/notepad-plus-plus/raw/master/snap/local/src/notepad-plus-plus.png -O notepad-plus-plus.png

wget -q "https://github.com/AppImageCrafters/appimage-builder/releases/download/v1.0.3/appimage-builder-1.0.3-x86_64.AppImage" -O builder ; chmod +x builder ; ./builder --appimage-extract &>/dev/null

# add custom mksquashfs
wget -q "https://github.com/mmtrt/WINE_AppImage/raw/master/runtime/mksquashfs" -O squashfs-root/usr/bin/mksquashfs

# force zstd format in appimagebuilder for appimages
rm builder ; sed -i 's|xz|zstd|' squashfs-root/usr/lib/python3.8/site-packages/appimagebuilder/modules/prime/appimage_primer.py

# Download 7zip cli upstream
wget -qO- https://www.7-zip.org/a/$(wget -qO- https://www.7-zip.org | grep -Eo -m2 '7z.*.exe"' | tail -1 | sed 's/.exe"/-linux-x64.tar.xz/') | tar -J -xvf - 7zz

# Add static appimage runtime
mkdir -p appimage-build/prime
wget -q "https://github.com/mmtrt/WINE_AppImage/raw/master/runtime/runtime-x86_64" -O appimage-build/prime/runtime-x86_64

ver=$(wget https://github.com/notepad-plus-plus/notepad-plus-plus/releases -qO - 2>&1 | grep -Eo ".*.x6" | grep npp | grep -Po "(\d+\.)+\d+" | head -n1)
wget -q https://github.com/$(wget -qO- https://github.com/notepad-plus-plus/notepad-plus-plus/releases | grep download/ | cut -d '"' -f2 | sed -n 5p)
./7zz x -aos "npp.$ver.Installer.exe" -x'!change.log' -x'!doLocalConf.xml' -x'!LICENSE' -x'!NppShell_06.dll' -x'!readme.txt' -x'!userDefinedLang-markdown.default.modern.xml' -o"npp-stable/usr/share/notepad-plus-plus" &>/dev/null
# winedata
appdir="npp-stable/usr/share/notepad-plus-plus"
mkdir -p "npp-stable/winedata/Application Data/Notepad++" && mkdir -p "npp-stable/usr/share/notepad-plus-plus/plugins/Config"
mv $appdir/notepad++.exe $appdir/notepad-plus-plus.exe
cp -R $appdir/'$_14_'/* "npp-stable/winedata/Application Data/Notepad++";cp -R $appdir/'$_15_'/* "npp-stable/usr/share/notepad-plus-plus/plugins";cp -R $appdir/'$_17_'/* "npp-stable/usr/share/notepad-plus-plus/plugins/Config"
find $appdir/'$PLUGINSDIR' -type f -name '*.xml' -print0 | while read -d $'\0' file; do cp -v "$file" $appdir/localization/ &>/dev/null; done
rm -R $appdir/'$_14_';rm -R $appdir/'$_15_';rm -R $appdir/'$_17_';rm -R $appdir/'$PLUGINSDIR';
find "npp-stable/usr" -type d -execdir chmod 755 {} + && find "npp-stable/winedata" -type d -execdir chmod 755 "{}" +

mkdir -p npp-stable/usr/bin ; mkdir -p npp-stable/usr/share/icons; cp notepad-plus-plus.desktop npp-stable ; cp wrapper npp-stable ; sed -i -e 's|progVer=|progVer='"$ver"'|g' npp-stable/wrapper ; cp notepad-plus-plus.png npp-stable/usr/share/icons

mkdir -p AppDir/winedata ; cp -r "npp-stable/"* AppDir

wget -q https://github.com/mmtrt/WINE_AppImage/releases/download/continuous-stable-4-i386/wine-stable-i386_4.0.4-x86_64.AppImage
chmod +x *.AppImage ; mv wine-stable-i386_4.0.4-x86_64.AppImage wine-stable.AppImage

# Create WINEPREFIX
./wine-stable.AppImage wineboot ; sleep 5

# Removing any existing user data
( cd "$WINEPREFIX/drive_c/" ; rm -rf users ) || true

echo "disabled" > $WINEPREFIX/.update-timestamp

sed -i "8d" npp.yml

sed -i 's/stable|/stable-wp|/' npp.yml

./squashfs-root/AppRun --recipe npp.yml

}

nppsbx86 () {

# Download icon:
wget -q https://github.com/mmtrt/notepad-plus-plus/raw/master/snap/local/src/notepad-plus-plus.png -O notepad-plus-plus.png

wget -q "https://github.com/AppImageCrafters/appimage-builder/releases/download/v1.0.3/appimage-builder-1.0.3-x86_64.AppImage" -O builder ; chmod +x builder ; ./builder --appimage-extract &>/dev/null

# add custom mksquashfs
wget -q "https://github.com/mmtrt/WINE_AppImage/raw/master/runtime/mksquashfs" -O squashfs-root/usr/bin/mksquashfs

# force zstd format in appimagebuilder for appimages
rm builder ; sed -i 's|xz|zstd|' squashfs-root/usr/lib/python3.8/site-packages/appimagebuilder/modules/prime/appimage_primer.py

# Download 7zip cli upstream
wget -qO- https://www.7-zip.org/a/$(wget -qO- https://www.7-zip.org | grep -Eo -m2 '7z.*.exe"' | tail -1 | sed 's/.exe"/-linux-x64.tar.xz/') | tar -J -xvf - 7zz

# Add static appimage runtime
mkdir -p appimage-build/prime
wget -q "https://github.com/mmtrt/WINE_AppImage/raw/master/runtime/runtime-aarch64" -O appimage-build/prime/runtime-aarch64

ver=$(wget https://github.com/notepad-plus-plus/notepad-plus-plus/releases -qO - 2>&1 | grep -Eo ".*.x6" | grep npp | grep -Po "(\d+\.)+\d+" | head -n1)
wget -q https://github.com/$(wget -qO- https://github.com/notepad-plus-plus/notepad-plus-plus/releases | grep download/ | cut -d '"' -f2 | sed -n 5p)
./7zz x -aos "npp.$ver.Installer.exe" -x'!change.log' -x'!doLocalConf.xml' -x'!LICENSE' -x'!NppShell_06.dll' -x'!readme.txt' -x'!userDefinedLang-markdown.default.modern.xml' -o"npp-stable/usr/share/notepad-plus-plus" &>/dev/null
# winedata
appdir="npp-stable/usr/share/notepad-plus-plus"
mkdir -p "npp-stable/winedata/Application Data/Notepad++" && mkdir -p "npp-stable/usr/share/notepad-plus-plus/plugins/Config"
mv $appdir/notepad++.exe $appdir/notepad-plus-plus.exe
cp -R $appdir/'$_14_'/* "npp-stable/winedata/Application Data/Notepad++";cp -R $appdir/'$_15_'/* "npp-stable/usr/share/notepad-plus-plus/plugins";cp -R $appdir/'$_17_'/* "npp-stable/usr/share/notepad-plus-plus/plugins/Config"
find $appdir/'$PLUGINSDIR' -type f -name '*.xml' -print0 | while read -d $'\0' file; do cp -v "$file" $appdir/localization/ &>/dev/null; done
rm -R $appdir/'$_14_';rm -R $appdir/'$_15_';rm -R $appdir/'$_17_';rm -R $appdir/'$PLUGINSDIR';
find "npp-stable/usr" -type d -execdir chmod 755 {} + && find "npp-stable/winedata" -type d -execdir chmod 755 "{}" +
rm ./*.exe

mkdir -p npp-stable/usr/bin ; mkdir -p npp-stable/usr/share/icons; cp notepad-plus-plus.desktop npp-stable ; cp wrapper npp-stable ; sed -i -e 's|progVer=|progVer='"$ver"'|g' npp-stable/wrapper ; cp notepad-plus-plus.png npp-stable/usr/share/icons

mkdir -p AppDir/winedata ; cp -r "npp-stable/"* AppDir

./squashfs-root/AppRun --recipe npp-box86.yml
}

if [ "$1" == "stable" ]; then
    npps
    ( mkdir -p dist ; mv notepad-plus-plus*.AppImage* dist/. ; cd dist || exit ; chmod +x ./*.AppImage )
elif [ "$1" == "stablewp" ]; then
    nppswp
    ( mkdir -p dist ; mv notepad-plus-plus*.AppImage* dist/. ; cd dist || exit ; chmod +x ./*.AppImage )
elif [ "$1" == "stable-box86" ]; then
    nppsbx86
    ( mkdir -p dist ; mv notepad-plus-plus*.AppImage* dist/. ; cd dist || exit ; chmod +x ./*.AppImage )
fi
