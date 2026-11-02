#!/bin/bash
# Builds fheroes2 for iPad 1 (iOS 5.1.1) and packages it into a .deb for jailbroken devices.
# Requires build_libcxx.sh, build_sdl.sh and build_mixer.sh to be run first.
set -e
. "$(dirname "$0")/env.sh"

ROOT=$(cd $IOS5_DIR/.. && pwd)
SRC=$ROOT/src
OBJ=$DEPS/build-game
APP=$DEPS/pkg/Applications/fheroes2.app
mkdir -p $OBJ

# Game data (HEROES2.AGG etc.) goes here; reachable over USB with iFunBox-like tools.
DATA_DIR=/var/mobile/Media/fheroes2

INCLUDES="-I$PREFIX/include/SDL2 -I$SRC/engine -I$SRC/thirdparty/libsmacker"
for d in agg ai army audio battle campaign castle dialog editor game gui h2d heroes image kingdom maps monster resource spell system world; do
  INCLUDES="$INCLUDES -I$SRC/fheroes2/$d"
done

# TLS is unsupported before iOS 8: all thread_local variables in fheroes2 are function-level caches.
DEFS="-D__IPHONEOS__=1 -Dthread_local=static -DFHEROES2_DATA=$DATA_DIR -DNDEBUG"
CXXFLAGS="$CXX_STD_FLAGS -O2 $DEFS $INCLUDES -Wno-macro-redefined -include $COMPAT_DIR/compat_sdl.h"
CFLAGS="-O2 $DEFS $INCLUDES"

SRCS="$(find $SRC/engine $SRC/fheroes2 -name '*.cpp') $SRC/thirdparty/libsmacker/smacker.c $COMPAT_DIR/compat_subscript.m"

# Incremental: rebuild an object only when its source is newer.
for f in $SRCS; do
  o=$OBJ/$(echo ${f#$ROOT/} | tr / _).o
  [ "$o" -nt "$f" ] && continue
  case $f in
    *.cpp) echo "$CXX $CXXFLAGS -c $f -o $o" ;;
    *.m)   echo "$CC -x objective-c -O2 -fobjc-arc -c $f -o $o" ;;
    *)     echo "$CC $CFLAGS -c $f -o $o" ;;
  esac
done > $OBJ/commands.txt
echo "compiling $(wc -l < $OBJ/commands.txt) files"
xargs -P $JOBS -I{} sh -c '{}' < $OBJ/commands.txt

rm -rf $DEPS/pkg && mkdir -p $APP
# SDL 2.0.12 provides main() itself.
rm -f $OBJ/ios_SDL_uikit_main.c.o
$CXX -o $APP/fheroes2_bin $OBJ/*.o -nostdlib++ -L$PREFIX/lib -lSDL2_mixer -lvorbis -logg -lSDL2 -lc++ -lc++abi -lz -liconv \
  -framework UIKit -framework Foundation -framework QuartzCore -framework OpenGLES -framework CoreGraphics \
  -framework AudioToolbox -framework CoreAudio -framework AVFoundation -framework CoreMotion -dead_strip \
  -Wl,-flat_namespace
# Flat namespace above: the 9.3 SDK binds symbols to libraries they moved to after iOS 5
# (e.g. NSObject is expected in libobjc). Our own symbols still win, the executable is searched first.
$TC/ldid -S $APP/fheroes2_bin
# Launcher script keeps stderr (the game log) in the data folder.
cp $IOS5_DIR/package/launcher.sh $APP/fheroes2
chmod 0755 $APP/fheroes2

# Bundle resources: fheroes2 looks for files/ next to the executable.
mkdir -p $APP/files/data $APP/files/lang
cp $ROOT/files/data/resurrection.h2d $APP/files/data/
# MIDI music (demo and DOS data) via Timidity with GUS patches. SDL_mixer 2.0.4 takes the config
# from TIMIDITY_CFG (set by the launcher); instrument paths in it are relative, so point "dir" at them.
cp -r $ROOT/files/timidity $APP/files/
sed -i 's/\r$//' $APP/files/timidity/timidity.cfg
sed -i '1i dir /Applications/fheroes2.app/files/timidity' $APP/files/timidity/timidity.cfg
if command -v msgfmt > /dev/null; then
  for po in uk ru en; do
    [ -f $ROOT/files/lang/$po.po ] && msgfmt $ROOT/files/lang/$po.po -o $APP/files/lang/$po.mo
  done
fi
cp $IOS5_DIR/package/Info.plist $APP/
[ -f $IOS5_DIR/package/Icon.png ] && cp $IOS5_DIR/package/Icon*.png $APP/

mkdir -p $DEPS/pkg/DEBIAN
cp $IOS5_DIR/package/control $DEPS/pkg/DEBIAN/
chmod 0755 $DEPS/pkg/DEBIAN
mkdir -p $DEPS/packages
DEB=$DEPS/packages/fheroes2-ios5.deb
dpkg-deb -Zgzip -b $DEPS/pkg $DEB > /dev/null
ls -la $APP/fheroes2_bin $DEB
