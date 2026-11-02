#!/bin/bash
# Builds static libc++ and libc++abi (LLVM 11.1.0) for iOS 5.
# iOS 5 has no C++17 runtime (std::filesystem etc.), so we link our own.
set -e
. "$(dirname "$0")/env.sh"

V=11.1.0
cd $DEPS
for p in libcxx libcxxabi; do
  [ -f $p-$V.src.tar.xz ] || curl -sSLO https://github.com/llvm/llvm-project/releases/download/llvmorg-$V/$p-$V.src.tar.xz
  [ -d $p-$V.src ] || tar xJf $p-$V.src.tar.xz
done

CXXSRC=$DEPS/libcxx-$V.src
ABISRC=$DEPS/libcxxabi-$V.src

# Install headers with an empty __config_site (defaults are fine for Darwin).
rm -rf $PREFIX/include/c++
mkdir -p $PREFIX/include/c++/v1
cp -r $CXXSRC/include/* $PREFIX/include/c++/v1/
rm -f $PREFIX/include/c++/v1/CMakeLists.txt $PREFIX/include/c++/v1/__config_site.in
{ echo "#ifndef _LIBCPP_CONFIG_SITE"; echo "#define _LIBCPP_CONFIG_SITE"; echo "#endif"; } > $PREFIX/include/c++/v1/__config_site
# Prepend the config site include the way the CMake build does it.
sed -i '1s;^;#include <__config_site>\n;' $PREFIX/include/c++/v1/__config
cp $ABISRC/include/*.h $PREFIX/include/c++/v1/

COMMON="-O2 -fvisibility-inlines-hidden -Wno-user-defined-literals -I$CXXSRC/src -I$ABISRC/include -include $COMPAT_DIR/compat_time.h"

OBJ=$DEPS/build-libcxx
rm -rf $OBJ && mkdir -p $OBJ/cxx $OBJ/abi

# libc++abi
for f in abort_message cxa_aux_runtime cxa_default_handlers cxa_demangle cxa_exception cxa_exception_storage \
         cxa_guard cxa_handlers cxa_personality cxa_vector cxa_virtual fallback_malloc private_typeinfo \
         stdlib_exception stdlib_stdexcept stdlib_typeinfo stdlib_new_delete; do
  echo "$CXX $CXX_STD_FLAGS $COMMON -D_LIBCXXABI_BUILDING_LIBRARY -D_LIBCPP_BUILDING_LIBRARY -c $ABISRC/src/$f.cpp -o $OBJ/abi/$f.o"
done | xargs -P $JOBS -I{} sh -c '{}'

# libc++ (with LIBCXX_BUILDING_LIBCXXABI new.cpp leaves operator new/delete to libc++abi)
for f in algorithm any atomic barrier bind charconv chrono condition_variable condition_variable_destructor debug \
         exception functional future hash ios iostream locale memory mutex mutex_destructor new optional random \
         random_shuffle regex shared_mutex stdexcept string strstream system_error thread typeinfo utility valarray \
         variant vector filesystem/directory_iterator filesystem/operations filesystem/int128_builtins; do
  o=$OBJ/cxx/$(echo $f | tr / _).o
  echo "$CXX $CXX_STD_FLAGS $COMMON -D_LIBCPP_BUILDING_LIBRARY -DLIBCXX_BUILDING_LIBCXXABI -c $CXXSRC/src/$f.cpp -o $o"
done | xargs -P $JOBS -I{} sh -c '{}'

rm -f $PREFIX/lib/libc++.a $PREFIX/lib/libc++abi.a
$AR rc $PREFIX/lib/libc++.a $OBJ/cxx/*.o
$AR rc $PREFIX/lib/libc++abi.a $OBJ/abi/*.o
$RANLIB $PREFIX/lib/libc++.a $PREFIX/lib/libc++abi.a
ls -la $PREFIX/lib/libc++*.a
