#!/bin/sh

if [ -n "" ]
then
	export AS="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
else
	if [ -n "" ]
	then
		export AS=""
	fi
fi
export CC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
export CXX="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++"
export OBJC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
export LD="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ld"
export AR="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar"
export RANLIB="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib"
export STRIP="CMAKE_STRIP-NOTFOUND"
export NM="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/nm"
export CC_NO_LAUNCHER="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
export CXX_NO_LAUNCHER="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++"
export OBJC_NO_LAUNCHER="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"

ASFLAGS=" "
CPPFLAGS="  -w"
CFLAGS=" "
CXXFLAGS=" "
OBJCFLAGS=" "
LDFLAGS=" "

export PATH="$PATH:/Users/eicaptain/Desktop/linphone-iphone/WORK/ios-armv7/cmake/programs"
export PKG_CONFIG="/usr/local/bin/pkg-config"
export PKG_CONFIG_PATH=""
export PKG_CONFIG_LIBDIR="/Users/eicaptain/Desktop/linphone-iphone/liblinphone-sdk/armv7-apple-darwin.ios/lib/pkgconfig"

cd "/Users/eicaptain/Desktop/linphone-iphone/WORK/ios-armv7/Build/vpx"

if [ ! -f "vpx_config.h" ]
then
	 
	CC=$CC_NO_LAUNCHER LD=$CC_NO_LAUNCHER ASFLAGS=$ASFLAGS CFLAGS=$CFLAGS LDFLAGS=$LDFLAGS "/Users/eicaptain/Desktop/linphone-iphone/submodules/externals/libvpx/configure"  "--prefix=/Users/eicaptain/Desktop/linphone-iphone/liblinphone-sdk/armv7-apple-darwin.ios" "--target=armv7-darwin-gcc" "--prefix=/Users/eicaptain/Desktop/linphone-iphone/liblinphone-sdk/armv7-apple-darwin.ios" "--target=armv7-darwin-gcc" "--enable-static" "--disable-shared" "--enable-error-concealment" "--enable-multithread" "--enable-realtime-only" "--enable-spatial-resampling" "--enable-vp8" "--disable-vp9" "--enable-libs" "--disable-install-docs" "--disable-debug-libs" "--disable-examples" "--disable-unit-tests" "--as=yasm" 
fi
