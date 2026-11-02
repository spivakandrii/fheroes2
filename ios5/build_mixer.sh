#!/bin/bash
# Builds static SDL2_mixer 2.0.4 for iOS 5: WAV/VOC/AIFF sounds, OGG music (needs build_ogg.sh)
# and MIDI through the built-in Timidity (uses fheroes2's files/timidity, see package/launcher.sh).
set -e
. "$(dirname "$0")/env.sh"

V=2.0.4
cd $DEPS
[ -f SDL2_mixer-$V.tar.gz ] || curl -sSL -o SDL2_mixer-$V.tar.gz https://github.com/libsdl-org/SDL_mixer/archive/refs/tags/release-$V.tar.gz
rm -rf SDL_mixer-release-$V && tar xzf SDL2_mixer-$V.tar.gz
S=$DEPS/SDL_mixer-release-$V

OBJ=$DEPS/build-mixer
rm -rf $OBJ && mkdir -p $OBJ
FLAGS="-O2 -I$PREFIX/include/SDL2 -I$PREFIX/include -I$S/timidity -DNDEBUG -DMUSIC_WAV -DMUSIC_OGG -DMUSIC_MID_TIMIDITY"

{
  for f in mixer music effect_position effect_stereoreverse effects_internal load_aiff load_voc music_wav music_ogg music_timidity; do
    echo "$CC $FLAGS -c $S/$f.c -o $OBJ/$f.o"
  done
  for f in common instrum mix output playmidi readmidi resample tables timidity; do
    echo "$CC $FLAGS -c $S/timidity/$f.c -o $OBJ/timidity_$f.o"
  done
} | xargs -P $JOBS -I{} sh -c '{}'

rm -f $PREFIX/lib/libSDL2_mixer.a
$AR rc $PREFIX/lib/libSDL2_mixer.a $OBJ/*.o
$RANLIB $PREFIX/lib/libSDL2_mixer.a
cp $S/SDL_mixer.h $PREFIX/include/SDL2/
ls -la $PREFIX/lib/libSDL2_mixer.a
