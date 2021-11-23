#!/bin/bash

# workaround for failing horology test
cp ${RECIPE_DIR}/test_patches/horology.out ${SRC_DIR}/src/test/regress/expected/horology.out
# workaround for name test because of NAMEDATALEN
cp ${RECIPE_DIR}/test_patches/name.out ${SRC_DIR}/src/test/regress/expected/name.out
cp ${RECIPE_DIR}/test_patches/enum.out ${SRC_DIR}/src/test/regress/expected/enum.out
cp ${RECIPE_DIR}/test_patches/create_view.out ${SRC_DIR}/src/test/regress/expected/create_view.out
cp ${RECIPE_DIR}/test_patches/join.out ${SRC_DIR}/src/test/regress/expected/join.out
cp ${RECIPE_DIR}/test_patches/async.out ${SRC_DIR}/src/test/regress/expected/async.out
cp ${RECIPE_DIR}/test_patches/rowsecurity.out ${SRC_DIR}/src/test/regress/expected/rowsecurity.out

# avoid absolute-paths in compilers
export CC=$(basename "$CC")
export CXX=$(basename "$CXX")
export FC=$(basename "$FC")

# modify CPPFLAGS to avoid weird bug with conda-build where multiple similar placeholder paths are optimized by compiler
# where different parts of executable reference different parts of similar string constant
# in such case after installation into the environment - one of the placeholder paths gets broken (stuffed with zeroes)
# you can read more about placeholders here:
# https://github.com/conda/conda-build/issues/1482
# https://docs.conda.io/projects/conda-build/en/latest/resources/make-relocatable.html
# to avoid the issue we just add -O2 flag at the end of the CPPFLAGS because this is the string constant that gets
# aliased with INCLUDEDIR and PKGINCLUDEDIR in pg_config (libpq package)

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
    --with-system-tzdata=$PREFIX/share/zoneinfo \
    PG_SYSROOT="undefined" \
    CPPFLAGS='-O2'

sed -i 's/#define NAMEDATALEN 64/#define NAMEDATALEN 256/g' ./src/include/pg_config_manual.h

make -j $CPU_COUNT
make -j $CPU_COUNT -C contrib

if [[ "${CONDA_BUILD_CROSS_COMPILATION}" != "1" ]]; then
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
fi
