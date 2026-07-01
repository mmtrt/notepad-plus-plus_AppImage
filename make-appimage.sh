#!/bin/sh

# ─── Shared helpers ────────────────────────────────────────────────────────────

get_stable_ver() {
    wget https://github.com/notepad-plus-plus/notepad-plus-plus/releases -qO - 2>&1 \
        | grep -Eo ".*.x6" | grep npp | grep -Po "(\d+\.)+\d+" | head -n1
}

get_7zz() {
    wget -qO- "https://www.7-zip.org/a/$(
        wget -qO- https://www.7-zip.org \
            | grep -Eo -m2 '7z.*.exe"' | tail -1 \
            | sed 's/.exe"/-linux-x64.tar.xz/' | cut -d'/' -f6
    )" | tar -J -xvf - 7zz
}

# Deploy Wine + multimedia libraries into AppDir via quick-sharun.
deploy_wine_deps() {
    mkdir -p /tmp/wine
    WINEPREFIX=/tmp/wine quick-sharun \
        /usr/bin/wine*             \
        /usr/lib/wine              \
        /usr/bin/msidb             \
        /usr/bin/msiexec           \
        /usr/bin/notepad           \
        /usr/bin/regedit           \
        /usr/bin/regsvr32          \
        /usr/bin/widl              \
        /usr/bin/wmc               \
        /usr/bin/wrc               \
        /usr/bin/function_grep.pl  \
        /usr/bin/cabextract        \
        /usr/lib/libfreetype.so*   \
        /usr/lib/libharfbuzz*      \
        /usr/lib/libgraphite*      \
        /usr/lib/libavcodec.so*    \
        /usr/lib/libavdevice.so*   \
        /usr/lib/libavfilter.so*   \
        /usr/lib/libavformat.so*   \
        /usr/lib/libavutil.so*     \
        /usr/lib/libswresample.so* \
        /usr/lib/libswscale.so*    \
        /usr/bin/wget              \
        /usr/bin/zenity
}

# Patch the Wine binary so it works correctly inside the AppDir/sharun layout.
patch_wine_binary() {

    # alright here the pain starts
    ln -sr ./AppDir/lib/wine/x86_64-unix/*.so* ./AppDir/bin

    # this gets broken by sharun somehow
    kek=".$(tr -dc 'A-Za-z0-9_=-' < /dev/urandom | head -c 10)"
    rm -f ./AppDir/lib/wine/x86_64-unix/wine
    cp /usr/lib/wine/x86_64-unix/wine ./AppDir/lib/wine/x86_64-unix/wine
    patchelf --set-interpreter "/tmp/${kek}" ./AppDir/lib/wine/x86_64-unix/wine
    # we used to run patchelf --add-needed anylinux.so on the wine binary
    # but after 11.8 this causes the binary to break horribly:
    # AppDir/lib/wine/x86_64-unix/wine: oops... not enough space for load commands
    # so we will have to make sure anylinux.so loads by adding it as a dependency to the libc
    patchelf --add-needed anylinux.so ./AppDir/shared/lib/libc.so.6

    cat > ./AppDir/bin/random-linker.src.hook <<EOF
#!/bin/sh
cp -f "\$APPDIR"/shared/lib/ld-linux*.so* /tmp/"${kek}"
EOF
    chmod +x ./AppDir/bin/*.hook

    # Set the lib path to also use wine libs
    echo 'LD_LIBRARY_PATH=${APPDIR}/lib:${APPDIR}/lib/pulseaudio:${APPDIR}/lib/alsa-lib:${APPDIR}/lib/wine/x86_64-unix' \
        >> ./AppDir/.env

    # lib/wine/x86_64-unix/wine will try to execute a relative ../../bin/wineserver
    # which resolves to shared/bin/wineserver and it is wrong
    # so we have to make AppDir/shared/lib the symlink and AppDir/lib the real directory
    # that way ../../bin/wineserver resolves to the sharun hardlink
    if [ -L ./AppDir/lib ]; then
        rm -f ./AppDir/lib
        mv ./AppDir/shared/lib ./AppDir
        ln -sr ./AppDir/lib ./AppDir/shared
    fi
}

# ─── Build function ────────────────────────────────────────────────────────────

npp_build() {
    stable_ver="$(get_stable_ver)"
    appname="notepad-plus-plus"
    upinfo_tag="test-any"

    get_7zz

    # Download installer
    wget -q "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/latest/download/npp.${stable_ver}.Installer.x64.exe"

    # Extract installer contents
    _appdir="npp-stable/share/notepad-plus-plus"
    mkdir -p "$_appdir"
    ./7zz x -aos "npp.${stable_ver}.Installer.x64.exe" \
        -x'!change.log' -x'!doLocalConf.xml' -x'!LICENSE' \
        -x'!NppShell_06.dll' -x'!readme.txt' \
        -x'!userDefinedLang-markdown.default.modern.xml' \
        -o"$_appdir" >/dev/null 2>&1

    # Rename exe to match _NPP_BIN
    mv "$_appdir/notepad++.exe" "$_appdir/notepad-plus-plus.exe"

    # Move installer-injected dirs to winedata / plugins
    mkdir -p "npp-stable/winedata/Application Data/Notepad++" \
             "$_appdir/plugins/Config"
    cp -R "$_appdir/\$_23_/." "npp-stable/winedata/Application Data/Notepad++"
    cp -R "$_appdir/\$_24_/." "$_appdir/plugins/"
    cp -R "$_appdir/\$_26_/." "$_appdir/plugins/Config/"
    find "$_appdir/\$PLUGINSDIR" -type f -name '*.xml' \
        -exec cp -v {} "$_appdir/localization/" \; >/dev/null 2>&1 || true
    rm -rf "$_appdir/\$_23_" "$_appdir/\$_24_" "$_appdir/\$_26_" \
           "$_appdir/\$PLUGINSDIR"

    find "npp-stable/share" -type d -execdir chmod 755 {} +
    rm -f ./*.exe

    # Copy reg files to winedata
    cp dark.reg light.reg "npp-stable/winedata/"

    # Copy into AppDir
    cp -r npp-stable/* AppDir

    sed -i -e "s|Version=|Version=${stable_ver}|" notepad-plus-plus.desktop

    export ARCH="$(uname -m)"
    export VERSION="${stable_ver}"
    export OUTNAME="${appname}-${VERSION}-anylinux-${ARCH}.AppImage"
    export OUTPATH=./dist
    export ADD_HOOKS="self-updater.hook"
    export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|${upinfo_tag}|*${ARCH}.AppImage.zsync"
    export ICON=notepad-plus-plus.png
    export DESKTOP=notepad-plus-plus.desktop
    export APPNAME=notepad-plus-plus
    export DEPLOY_SDL=1
    export DEPLOY_PIPEWIRE=1
    export DEPLOY_GSTREAMER=1
    export DEPLOY_VULKAN=1
    export DEPLOY_OPENGL=1
    export STRACE_BINARY=wine
    export STRACE_FLAGS="$_appdir/notepad-plus-plus.exe"

    deploy_wine_deps

    echo "${stable_ver}" > AppDir/version

    # Patch version into hook
    sed -i -e "s|_NPP_VER=|_NPP_VER=${stable_ver}|" AppDir/bin/notepad-plus-plus.hook

    # Silence "pci id for fd" Mesa/DRI noise from bundled libs
    find AppDir/lib -name '*.so*' ! -type l -print0 \
        | xargs -0 grep -rl 'pci id for fd' \
        | xargs perl -i -0777 -pe 's/pci id for fd[^\x00]*/"\x00" x length($&)/ge'

    # Install latest winetricks
    wget --retry-connrefused --tries=30 \
        https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
        -O ./AppDir/bin/winetricks
    chmod +x ./AppDir/bin/winetricks

    patch_wine_binary

    # Turn AppDir into AppImage
    quick-sharun --make-appimage

    # Test the app for 12 seconds, if the test fails due to the app
    # having issues running in the CI use --simple-test instead
    quick-sharun --test ./dist/*.AppImage
}

# ─── Dispatch ──────────────────────────────────────────────────────────────────

case "$1" in
    stable)   npp_build ;;
    *) echo "Usage: $0 {stable}" >&2; exit 1 ;;
esac
