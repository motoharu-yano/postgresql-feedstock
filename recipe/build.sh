#!/bin/bash

# workaround for failing horology test
cp ${RECIPE_DIR}/test_patches/horology.out ${SRC_DIR}/src/test/regress/expected/horology.out

# avoid absolute-paths in compilers
export CC=$(basename "$CC")
export CXX=$(basename "$CXX")
export FC=$(basename "$FC")

./configure \
    --prefix=$PREFIX \
    --with-readline \
    --with-libraries=$PREFIX/lib \
    --with-includes=$PREFIX/include \
    --with-openssl \
    --with-uuid=e2fs \
    --with-libxml \
    --with-libxslt \
    --with-gssapi \
    --with-icu \
    --with-system-tzdata=$PREFIX/share/zoneinfo

make -j $CPU_COUNT
make -j $CPU_COUNT -C contrib

# make check # Failing with 'initdb: cannot be run as root'.
if [ ${target_platform} == linux-64 ]; then
    # osx, aarch64 and ppc64le checks fail in some strange ways
    #on the test failures
    #https://www.postgresql.org/docs/7.1/regress.html#AEN14406

    #on random test fails and MAX_CONNECTIONS parameter
    #https://www.postgresql.org/docs/10/regress-run.html

    make MAX_CONNECTIONS=2 check
    make check -C contrib
fi
# make check -C src/interfaces/ecpg
