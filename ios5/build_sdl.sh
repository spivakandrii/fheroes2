#!/bin/bash
# Builds static SDL 2.0.12 for iOS 5 (UIKit + OpenGL ES, no Metal/MFi/HIDAPI).
# SDL 2.0.12 officially goes back to iOS 6.1; iOS 5 gaps are patched as they show up.
set -e
. "$(dirname "$0")/env.sh"

V=2.0.12
cd $DEPS
[ -f SDL2-$V.tar.gz ] || curl -sSL -o SDL2-$V.tar.gz https://github.com/libsdl-org/SDL/releases/download/release-$V/SDL2-$V.tar.gz
rm -rf SDL2-$V && tar xzf SDL2-$V.tar.gz
S=$DEPS/SDL2-$V

# Features that need iOS 7+ frameworks or are not needed on iPad 1.
sed -i -E '/define (SDL_JOYSTICK_MFI|SDL_JOYSTICK_HIDAPI|SDL_SENSOR_COREMOTION|SDL_VIDEO_RENDER_METAL|SDL_VIDEO_VULKAN|SDL_VIDEO_METAL|SDL_IPHONE_LAUNCHSCREEN)\b/d' \
  $S/include/SDL_config_iphoneos.h

python3 -I $IOS5_DIR/patch_sdl.py $S

SRCS="$(ls $S/src/*.c $S/src/atomic/*.c $S/src/audio/*.c $S/src/audio/coreaudio/*.m $S/src/audio/dummy/*.c \
  $S/src/cpuinfo/*.c $S/src/dynapi/*.c $S/src/events/*.c $S/src/file/*.c $S/src/file/cocoa/*.m \
  $S/src/filesystem/cocoa/*.m $S/src/haptic/*.c $S/src/haptic/dummy/*.c \
  $S/src/joystick/*.c $S/src/joystick/iphoneos/*.m $S/src/joystick/steam/*.c \
  $S/src/libm/*.c $S/src/loadso/dlopen/*.c $S/src/power/*.c $S/src/power/uikit/*.m \
  $S/src/render/*.c $S/src/render/opengles/*.c $S/src/render/opengles2/*.c $S/src/render/software/*.c \
  $S/src/sensor/*.c $S/src/sensor/dummy/*.c $S/src/stdlib/*.c \
  $S/src/thread/*.c $S/src/thread/pthread/*.c $S/src/timer/*.c $S/src/timer/unix/*.c \
  $S/src/video/*.c $S/src/video/uikit/*.m $S/src/video/dummy/*.c $S/src/video/yuv2rgb/*.c)"

OBJ=$DEPS/build-sdl
rm -rf $OBJ && mkdir -p $OBJ
FLAGS="-O2 -I$S/include -DNDEBUG -Wno-deprecated-declarations -Wunguarded-availability -fobjc-arc"

for f in $SRCS; do
  o=$OBJ/$(echo ${f#$S/src/} | tr / _).o
  case $f in
    *.m) echo "$CC -x objective-c $FLAGS -c $f -o $o" ;;
    *)   echo "$CC $FLAGS -c $f -o $o" ;;
  esac
done | xargs -P $JOBS -I{} sh -c '{} 2>>'$OBJ'/warnings.log'

rm -f $PREFIX/lib/libSDL2.a
$AR rc $PREFIX/lib/libSDL2.a $OBJ/*.o
$RANLIB $PREFIX/lib/libSDL2.a
rm -rf $PREFIX/include/SDL2 && mkdir -p $PREFIX/include/SDL2
cp $S/include/*.h $PREFIX/include/SDL2/
cp $S/include/SDL_config_iphoneos.h $PREFIX/include/SDL2/SDL_config.h
cp $S/src/main/uikit/SDL_uikit_main.c $PREFIX/lib/
ls -la $PREFIX/lib/libSDL2.a
echo "iOS 5 availability warnings:"
grep -c "only available on iOS" $OBJ/warnings.log || true
