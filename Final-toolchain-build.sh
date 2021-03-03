#!/bin/bash
#set -x

# sh Final-toolchain_build.sh x86_64 wrl7
export CFLAGS="-g -O0"
export CXXFLAGS="-g -O0"

WR_VERSION=$2

case $WR_VERSION in
	wrl8)
        GCC_VERSION=7.3.0
        BINUTILS_VERSION=2.29.1
        MPFR_VERSION=4.0.1
        MPC_VERSION=1.1.0
        GMP_VERSION=6.1.2
        GLIBC_VERSION=2.26
        KERNEL_VERSION=4.12

	;;

	wrl7)
        GCC_VERSION=4.8.1
        BINUTILS_VERSION=2.25.1
        MPFR_VERSION=3.1.6
        MPC_VERSION=1.0.3
        GMP_VERSION=6.1.2
        GLIBC_VERSION=2.22
        KERNEL_VERSION=4.1.10
        ;;

	*)
	echo "Pass the correct WR_VERSION"
	;;
esac

export CURR_DIR=`pwd`
export SRC=~/sources
export PREFIX=~/toolchain/$1-prefix
export BUILD=/winshare/build_tc

if [ ! -d $BUILD/build-binutils ]; then
    mkdir -p $BUILD/build-binutils-$BINUTILS_VERSION;
fi;
if [ ! -d $BUILD/build-gcc ]; then
    mkdir -p $BUILD/build-gcc-$GCC_VERSION;
fi;
if [ ! -d $BUILD/build-glibc ]; then
    mkdir -p $BUILD/build-glibc-$GLIBC_VERSION;
fi;

cd $SRC/gcc-$GCC_VERSION
sed -i '/k prot/agcc_cv_libc_provides_ssp=yes' gcc/configure

echo "Target to Build"
INPUT_ARCH=$1

case $INPUT_ARCH in
	arm|armeb)
           target=$INPUT_ARCH-windriver-linux-gnueabi
           program_prefix=$INPUT_ARCH-windriver-linux-gnueabi
            if [ $INPUT_ARCH == armeb ]; then
              target=$INPUT_ARCH-windriverv7atb-linux-gnueabi
	      program_prefix=$INPUT_ARCH-windriverv7atb-linux-gnueabi
	    fi
	   linux_arch=arm
	    ;;

	aarch64)
           # target=$INPUT_ARCH-windriver-linux
             target=$INPUT_ARCH-windriver-linux
             program_prefix=$INPUT_ARCH-windriver-linux
             linux_arch=arm64
            ;;

	powerpc|powerpc64|ppc|ppc64)
	   target=$INPUT_ARCH-windriver-linux
	   program_prefix=$INPUT_ARCH-windriver-linux
           linux_arch=powerpc
	   ;;
	mips|mips64)
           target=$INPUT_ARCH-windriver-linux
           program_prefix=$INPUT_ARCH-windriver-linux
	   linux_arch=mips
	   ;;
	x86_64)
           target=$INPUT_ARCH-windriver-linux
           program_prefix=$INPUT_ARCH-windriver-linux
	   linux_arch=x86
	   ;;
	x86)
           target=i586-windriver-linux
           program_prefix=i586-windriver-linux
	   linux_arch=x86
	   ;;
	i686)
          target=i686-windriver-linux
          program_prefix=i686-windriver-linux
          linux_arch=x86
	   ;;
	*)	
	   echo "Enter Valid arch{arm,arm64,powerpc,powerpc64,ppc,ppc64,mips,mips64,x86_64,x86,i586} to build."
	   exit 1
	;;
esac	  



cd $BUILD/build-binutils-$BINUTILS_VERSION
#1. Configuration used for Binutils 
echo "Binutils configure Running"
if ! $SRC/binutils-$BINUTILS_VERSION/configure --prefix=$PREFIX --build=x86_64-pc-linux --host=x86_64-pc-linux --target=$target --disable-silent-rules --program-prefix=$program_prefix- --disable-werror --enable-plugins --enable-gold --disable-multilib --enable-ld=default > configure.out 2>&1; then
echo "Binutils configure failed"
exit 1
fi;
echo "Binutils make Running"
if ! make -j2 > make.out 2>&1; then
echo "Binutils make failed"
exit 1
fi;
echo "Binutils make install Running"
if ! make -j2 install > makeinstall.out 2>&1; then
echo "Binutils make install failed"
exit 1
fi;

cd $SRC/linux-$KERNEL_VERSION
echo "Make in Linux Running"
if ! make -j2 ARCH=$linux_arch INSTALL_HDR_PATH=$PREFIX/$target headers_install > make.out 2>&1; then
echo "Make in Linux failed"
exit 1
fi;

export PATH=$PREFIX/bin:$PATH

#3. Configuration for GCC
cd $BUILD/build-gcc-$GCC_VERSION
echo "1st GCC configure Running"

case $INPUT_ARCH in
	powerpc|powerpc64|ppc|ppc64)
		if ! $SRC/gcc-$GCC_VERSION/configure --prefix=$PREFIX --build=x86_64-pc-linux --host=x86_64-pc-linux --target=$target --disable-silent-rules --program-prefix=$program_prefix- --with-gnu-ld --disable-werror --disable-shared --enable-languages=c --enable-threads=posix --enable-multilib --enable-c99 --enable-long-long --enable-symvers=gnu --enable-libstdcxx-pch --without-local-prefix --enable-libssp --disable-bootstrap --disable-libmudflap --with-system-zlib --with-linker-hash-style=gnu --enable-linker-build-id --with-ppl=no --with-cloog=no --enable-checking=release --enable-cheaders=c_global --with-long-double-128 --enable-poison-system-directories --enable-target-optspace --enable-nls --enable-__cxa_atexit > configure.out 2>&1; then
#NOTE:-- CHANGE CFLAG FOR DEBUG MODE 
		echo "1st GCC configure powerpc failed"
		exit 1
		fi;
		;;

	mips64)
		if ! $SRC/gcc-$GCC_VERSION/configure --prefix=$PREFIX --build=x86_64-pc-linux --host=x86_64-pc-linux --target=$target --program-prefix=$program_prefix- --disable-silent-rules 		  --disable-dependency-tracking 		   --with-gnu-ld --enable-shared --enable-languages=c,c++ --enable-threads=posix --disable-multilib --enable-c99 --enable-long-long --enable-symvers=gnu --enable-libstdcxx-pch --without-local-prefix --enable-target-optspace --enable-lto --enable-libssp --disable-bootstrap --disable-libmudflap --with-system-zlib --with-linker-hash-style=sysv --enable-linker-build-id --with-ppl=no --with-cloog=no --enable-checking=release --enable-cheaders=c_global  --enable-poison-system-directories --enable-nls --enable-__cxa_atexit --with-abi=64 --with-arch-64=mips64 --with-tune-64=mips64  > configure.out 2>&1; then
		echo "1st GCC configure mips64 failed"
		exit 1
		fi;
;;

	mips|x86_64|x86|i686)
        if ! $SRC/gcc-$GCC_VERSION/configure --prefix=$PREFIX --build=x86_64-pc-linux --host=x86_64-pc-linux --target=$target --disable-silent-rules --program-prefix=$program_prefix- --with-gnu-ld --disable-werror --disable-shared --enable-languages=c --enable-threads=posix --disable-multilib --enable-c99 --enable-long-long --enable-symvers=gnu --enable-libstdcxx-pch --without-local-prefix --enable-libssp --disable-bootstrap --disable-libmudflap --with-system-zlib --with-linker-hash-style=gnu --enable-linker-build-id --with-ppl=no --with-cloog=no --enable-checking=release --enable-cheaders=c_global --with-long-double-128 --enable-poison-system-directories --enable-target-optspace --enable-nls --enable-__cxa_atexit > configure.out 2>&1; then
		echo "1st GCC configure failed"
		exit 1
		fi;
		;;

	arm)
		if ! $SRC/gcc-$GCC_VERSION/configure --prefix=$PREFIX --build=x86_64-pc-linux --host=x86_64-pc-linux --target=$target --program-prefix=$program_prefix- --disable-silent-rules --disable-dependency-tracking --with-gnu-ld --enable-shared --enable-languages=c,c++ --enable-threads=posix --disable-multilib --enable-c99 --enable-long-long --enable-symvers=gnu --enable-libstdcxx-pch  --without-local-prefix --enable-target-optspace --enable-lto --enable-libssp --disable-bootstrap --disable-libmudflap --with-system-zlib --with-linker-hash-style=gnu --enable-linker-build-id --with-ppl=no --with-cloog=no --enable-checking=release --enable-cheaders=c_global   --enable-poison-system-directories  --enable-nls  > configure.out 2>&1; then
		echo "1st GCC configure arm failed"
		exit 1
		fi;
		;;

	aarch64)
		if ! $SRC/gcc-$GCC_VERSION/configure --prefix=$PREFIX --build=x86_64-pc-linux --host=x86_64-pc-linux --target=$target --program-prefix=$program_prefix- --exec_prefix=$PREFIX --disable-silent-rules --disable-dependency-tracking 		   --with-gnu-ld --enable-shared --enable-languages=c,c++ --enable-threads=posix --disable-multilib --enable-c99 --enable-long-long --enable-symvers=gnu --enable-libstdcxx-pch --without-local-prefix --enable-target-optspace --enable-lto --enable-libssp --disable-bootstrap --disable-libmudflap --with-system-zlib --with-linker-hash-style=gnu --enable-linker-build-id --with-ppl=no --with-cloog=no --enable-checking=release --enable-cheaders=c_global  --enable-poison-system-directories  --enable-nls --enable-__cxa_atexit  > configure.out 2>&1; then
		echo "1st GCC configure aarch64 failed"
		exit 1
		fi;
		;;

	armeb)
		if ! $SRC/gcc-$GCC_VERSION/configure --prefix=$PREFIX --build=x86_64-pc-linux --host=x86_64-pc-linux --target=$target --program-prefix=$program_prefix- --exec_prefix=$PREFIX --disable-silent-rules --disable-dependency-tracking  --with-gnu-ld --enable-shared --enable-languages=c,c++ --enable-threads=posix --disable-multilib --enable-c99 --enable-long-long --enable-symvers=gnu --enable-libstdcxx-pch --program-prefix=armeb-windriverv7atb-linux-gnueabi- --without-local-prefix --enable-target-optspace --enable-lto --enable-libssp --disable-bootstrap --disable-libmudflap --with-system-zlib --with-linker-hash-style=gnu --enable-linker-build-id --with-ppl=no --with-cloog=no --enable-checking=release --enable-cheaders=c_global --enable-poison-system-directories  --enable-nls --with-arch=armv7-a > configure.out 2>&1; then
		echo "1st GCC configure armeb failed"
		exit 1
		fi;
		;;


esac


echo "1st GCC make Running"
if ! make -j2 all-gcc > make1.out 2>&1; then
echo "1st GCC make failed"
exit 1
fi;
echo "1st GCC make install Running"
if ! make -j2 install-gcc > makeinstall1.out 2>&1; then
echo "1st GCC make install failed"
exit 1
fi;

#GCC Build finished backend
#exit 0

export CFLAGS=" -O2"
export CXXFLAGS=" -O2"

#4. GLIBC Default Configuration
cd $BUILD/build-glibc-$GLIBC_VERSION
echo "1st GLIBC configure Running"
if ! $SRC/glibc-$GLIBC_VERSION/configure --prefix=$PREFIX/$target --build=$MACHTYPE --host=$target --target=$target --with-headers=$PREFIX/$target/include --enable-shared --disable-multilib --disable-werror libc_cv_forced_unwind=yes > configure.out 2>&1; then
echo "1st GLIBC configure failed"
exit 1
fi;
echo "Install Headers Running"
if ! make -j2 install-bootstrap-headers=yes install-headers > install-headers.out 2>&1; then
echo "Install Headers failed"
exit 1
fi;
echo "1st GLIBC make Running"
if ! make -j2 csu/subdir_lib > make1.out 2>&1; then
echo "1st GLIBC make failed"
exit 1
fi;
echo "1st GLIBC Install Running"
if ! install csu/crt1.o csu/crti.o csu/crtn.o $PREFIX/$target/lib > makeinstall1.out 2>&1; then
echo "1st GLIBC Install failed"
exit 1
fi;
echo "1st GLIBC Shared lib Install Running"
if ! $program_prefix-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $PREFIX/$target/lib/libc.so > sharedinstall.out 2>&1; then
echo "1st GLIBC Shared lib Install failed"
exit 1
fi;
echo "1st GLIBC stub check Running"
if ! touch $PREFIX/$target/include/gnu/stubs.h > stub.out 2>&1; then
echo "1st GLIBC stub check failed"
exit 1
fi;

#4.1 GLIBC Configuration for 64-bit

export CFLAGS="-g -O0"
export CXXFLAGS="-g -O0"

#5. AGAIN GCC
cd $BUILD/build-gcc-$GCC_VERSION
echo "2nd GCC make Running"
if ! make -j2 all-target-libgcc > make2.out 2>&1; then
echo "2nd GCC make failed"
exit 1
fi;
echo "2nd GCC make install Running"
if ! make -j2 install-target-libgcc > makeinstall2.out 2>&1; then
echo "2nd GCC make install failed"
exit 1
fi;

export CFLAGS="-g -O2"
export CXXFLAGS="-g -O2"

#6. AGAIN GLIBC
cd $BUILD/build-glibc-$GLIBC_VERSION
echo "2nd GLIBC make Running"
if ! make -j2 > make2.out 2>&1; then
echo "2nd GLIBC make failed"
exit 1
fi;
#make -k -j2 > make2.out 2>&1
echo "2nd GLIBC make install Running"
#make -k -j2 install > makeinstall2.out 2>&1
if ! make -j2 install > makeinstall2.out 2>&1; then
echo "2nd GLIBC make install failed"
exit 1
fi;

export CFLAGS="-g -O0"
export CXXFLAGS="-g -O0"

#7. AGAIN GCC
cd $BUILD/build-gcc-$GCC_VERSION
echo "3rd GCC make Running"
if ! make -j2 > make3.out 2>&1; then
echo "3rd GCC make failed"
exit 1
fi;
echo "3rd GCC make install Running"
if ! make -j2 install > makeinstall3.out 2>&1; then
echo "3rd GCC make install failed as patch in libatomic/Makefile.* is not applied"
exit 1
fi;


