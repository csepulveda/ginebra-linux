u#!/bin/bash
# build-bash-full.sh

wget https://ftp.gnu.org/gnu/bash/bash-5.2.tar.gz
tar xzf bash-5.2.tar.gz
cd bash-5.2

make distclean 2>/dev/null

export PATH="$PWD/../i486-linux-musl-cross/bin:$PATH"
export CC=i486-linux-musl-gcc
export AR=i486-linux-musl-ar
export RANLIB=i486-linux-musl-ranlib
export CFLAGS="-Os"
export LDFLAGS="-static"

cat > config.cache << 'EOF'
bash_cv_func_strtoimax=yes
bash_cv_func_strtoumax=yes
ac_cv_func_strtoimax=yes
ac_cv_func_strtoumax=yes
bash_cv_must_reinstall_sighandlers=no
bash_cv_func_sigsetjmp=present
bash_cv_func_strcoll_broken=no
bash_cv_func_ctype_nonascii=no
bash_cv_dup2_broken=no
bash_cv_getenv_redef=yes
bash_cv_sys_siglist=yes
bash_cv_wcwidth_broken=no
EOF

./configure \
    --host=i486-linux-musl \
    --cache-file=config.cache \
    --enable-static-link \
    --without-bash-malloc \
    --disable-nls \
    --disable-bang-history \
    --disable-progcomp \
    --disable-net-redirections

make -j$(nproc) || true
i486-linux-musl-ar d lib/sh/libsh.a strtoimax.o 2>/dev/null
i486-linux-musl-ar d lib/sh/libsh.a strtoumax.o 2>/dev/null

make
i486-linux-musl-strip bash

cp bash ../
cd ..

rm -rf bash-5.2.tar.gz bash-5.2

file bash
ls -lh bash
