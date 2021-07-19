#!/bin/bash

# Convert and copy icon which is needed for desktop integration into place:
wget https://github.com/mmtrt/notepad-plus-plus/raw/master/snap/local/src/notepad-plus-plus.png -O notepad-plus-plus.png &>/dev/null
for width in 8 16 22 24 32 36 42 48 64 72 96 128 192 256; do
    dir=icons/hicolor/${width}x${width}/apps
    mkdir -p $dir
    convert notepad-plus-plus.png -resize ${width}x${width} $dir/notepad-plus-plus.png
done

wget -c "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
chmod +x ./appimagetool-x86_64.AppImage
./appimagetool-x86_64.AppImage --appimage-extract

npps () {

ver=$(wget https://api.github.com/repos/notepad-plus-plus/notepad-plus-plus/releases -qO - 2>&1 | grep "Notepad++ " | sed s'|"| |g' | awk '{print $5}' | head -n1)
wget https://github.com/$(wget -qO- https://github.com/notepad-plus-plus/notepad-plus-plus/releases | grep download/ | cut -d '"' -f2 | sed -n 5p) &> /dev/null
7z x -aos "npp.$ver.Installer.exe" -x'!change.log' -x'!doLocalConf.xml' -x'!LICENSE' -x'!NppShell_06.dll' -x'!readme.txt' -x'!userDefinedLang-markdown.default.modern.xml' -o"npp-stable/usr/share/notepad-plus-plus"
# winedata
appdir="npp-stable/usr/share/notepad-plus-plus"
mkdir -p "npp-stable/winedata/Application Data/Notepad++" && mkdir -p "npp-stable/usr/share/notepad-plus-plus/plugins/Config"
mv $appdir/notepad++.exe $appdir/notepad-plus-plus.exe
cp -R $appdir/'$_14_'/* "npp-stable/winedata/Application Data/Notepad++";cp -R $appdir/'$_15_'/* "npp-stable/usr/share/notepad-plus-plus/plugins";cp -R $appdir/'$_17_'/* "npp-stable/usr/share/notepad-plus-plus/plugins/Config"
find $appdir/'$PLUGINSDIR' -type f -name '*.xml' -print0 | while read -d $'\0' file; do cp -v "$file" $appdir/localization/ &>/dev/null; done
rm -R $appdir/'$_14_';rm -R $appdir/'$_15_';rm -R $appdir/'$_17_';rm -R $appdir/'$PLUGINSDIR';
find "npp-stable/usr" -type d -execdir chmod 755 {} + && find "npp-stable/winedata" -type d -execdir chmod 755 "{}" +
rm ./*.exe

mkdir -p npp-stable/usr/bin ; cp notepad-plus-plus.desktop npp-stable ; cp AppRun npp-stable ; sed -i -e 's|progVer=|progVer='"$ver"'|g' npp-stable/AppRun

cp -r icons npp-stable/usr/share ; cp notepad-plus-plus.png npp-stable

export ARCH=x86_64; squashfs-root/AppRun -v ./npp-stable -u "gh-releases-zsync|mmtrt|notepad-plus-plus_AppImage|stable|notepad*.AppImage.zsync" notepad-plus-plus_"${ver}"-${ARCH}.AppImage

}

nppswp () {

# # Disable FileOpenAssociations
# sudo sed -i 's|    LicenseInformation|    LicenseInformation,\\\n    FileOpenAssociations|g;$a \\n[FileOpenAssociations]\nHKCU,Software\\Wine\\FileOpenAssociations,"Enable",,"N"' /opt/wine-stable/share/wine/wine.inf
# # Disable winemenubuilder
# sudo sed -i 's|    FileOpenAssociations|    FileOpenAssociations,\\\n    DllOverrides|;$a \\n[DllOverrides]\nHKCU,Software\\Wine\\DllOverrides,"*winemenubuilder.exe",,""' /opt/wine-stable/share/wine/wine.inf
# sudo sed -i '/\%11\%\\winemenubuilder.exe -a -r/d' /opt/wine-stable/share/wine/wine.inf
# # Pre patching DPI setting DPI dword value 240=f0 180=b4 120=78 110=6e 100=64 96=60
# sudo sed -i 's|0x00000060|0x00000064|' /opt/wine-stable/share/wine/wine.inf

export WINEDLLOVERRIDES="mscoree,mshtml="
# export WINEARCH="win32"
export WINEPREFIX="/home/runner/.wine"
export WINEDEBUG="-all"
# export PATH=$PATH:"/opt/wine-stable/bin"

npps ; rm ./*AppImage*

wget -q https://github.com/mmtrt/WINE_AppImage/releases/download/continuous/wine-stable-i386_6.0.1-x86_64.AppImage ; chmod +x *.AppImage

# Create WINEPREFIX
./wine-stable-i386_6.0.1-x86_64.AppImage wineboot ; sleep 5 ; rm ./*.AppImage

# Removing any existing user data
( cd "$WINEPREFIX/drive_c/" ; rm -rf users ; rm windows/temp/* ) || true

cp -Rvp $WINEPREFIX npp-stable/ ; rm -rf $WINEPREFIX

( cd npp-stable ; wget -qO- 'https://gist.github.com/mmtrt/df659de58e36ee091e203ab3c1460619/raw/9a329972aced1227917ecd7747980d84c09e29f6/nppswp.patch' | patch -p1 )

export ARCH=x86_64; squashfs-root/AppRun -v ./npp-stable -n -u "gh-releases-zsync|mmtrt|notepad-plus-plus_AppImage|stable-wp|notepad*.AppImage.zsync" notepad-plus-plus_"${ver}"_WP-${ARCH}.AppImage

}

if [ "$1" == "stable" ]; then
    npps
elif [ "$1" == "stablewp" ]; then
    nppswp
fi
