#!/bin/bash

set -e

echo "[START] Setting up test environment for libpng CVE-2014-9495"

mkdir -p libpng_test && cd libpng_test

if [ ! -d libpng ]; then
  echo "[FETCH] Cloning libpng 1.5.20 (vulnerable) from GitHub..."
  git clone --branch v1.5.20 https://github.com/glennrp/libpng.git
else
  echo "libpng directory already exists, skipping clone."
fi

echo "[BUILD] Building libpng 1.5.20 (vulnerable)..."
cd libpng
mkdir -p build
cd build
CC=clang CFLAGS="-fsanitize=address -g" ../configure --disable-arm-neon --enable-shared --prefix=$(pwd)
make -j$(nproc)
make install
cd ../..

echo "[SETUP] Copying PoC source..."
cp ../write_exploit.c .

echo "🧪 [COMPILE] Building trigger_gen against libpng 1.5.20 (vulnerable)..."
gcc write_exploit.c -o trigger_vulnerable \
  -Ilibpng/build/include \
  -Llibpng/build/lib -lpng -fsanitize=address -g

echo ""
echo "=================================================="
echo "Running test with libpng 1.5.20 (VULNERABLE)"
echo "=================================================="

export LD_LIBRARY_PATH=$(pwd)/libpng/build/lib:$LD_LIBRARY_PATH

echo "ldd output for trigger_vulnerable:"
ldd ./trigger_vulnerable | grep png

LD_LIBRARY_PATH=$(pwd)/libpng/build/lib ./trigger_vulnerable || echo "Crash or error occurred during vulnerable test"

echo ""
echo "[COMPLETE] Vulnerable version test finished."
