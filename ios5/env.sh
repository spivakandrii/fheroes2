# Common cross-compilation environment for iPad 1 (armv7, iOS 5.1.1).
# Sourced by the build_*.sh scripts. Runs inside WSL.

TC=~/theos/toolchain/linux/iphone/bin
DEPS=~/fh2deps
# ARM-only copy of the Theos SDK, see fix_sdk.py.
SDK=$DEPS/iPhoneOS9.3-arm.sdk
[ -d $SDK ] || python3 -I "$(dirname "${BASH_SOURCE[0]}")/fix_sdk.py" ~/theos/sdks/iPhoneOS9.3.sdk $SDK
PREFIX=$DEPS/prefix
JOBS=$(nproc)

TARGET_FLAGS="-target armv7-apple-ios5.0 -isysroot $SDK -miphoneos-version-min=5.0"

CC="$TC/clang $TARGET_FLAGS"
CXX="$TC/clang++ $TARGET_FLAGS"
AR=$TC/llvm-ar
RANLIB=$TC/ranlib

# Our own libc++ is linked statically, so availability markup of the system libc++ does not apply.
CXX_STD_FLAGS="-std=c++17 -nostdinc++ -isystem $PREFIX/include/c++/v1 -D_LIBCPP_DISABLE_AVAILABILITY -faligned-allocation"
IOS5_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
COMPAT_DIR=$IOS5_DIR/compat

mkdir -p $PREFIX/include $PREFIX/lib
