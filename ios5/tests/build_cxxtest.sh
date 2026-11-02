#!/bin/bash
set -e
. "$(dirname "$0")/../env.sh"
cd "$(dirname "$0")"
$CXX $CXX_STD_FLAGS -O2 cxxtest.cpp -o $DEPS/cxxtest -nostdlib++ -L$PREFIX/lib -lc++ -lc++abi
$TC/ldid -S $DEPS/cxxtest
file $DEPS/cxxtest
