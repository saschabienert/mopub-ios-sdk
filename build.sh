#!/bin/bash

EXEC_PATH=`pwd`
PROJ_PATH="$EXEC_PATH/Heyzap"
BUILD_PATH="$EXEC_PATH/sdk-build"
SDK_BUILD_PATH="$PROJ_PATH/build"
ADS_BUILD_PATH="$EXEC_PATH/ads-sdk-build"

if [ $# -gt 0 ]; then
    sed -i "" "s/^#define\ SDK_VERSION.*/#define\ SDK_VERSION\ @\"$1\"/" Heyzap/Heyzap/HeyzapSDKPrivate.h
fi

ant -buildfile build.xml all

# Build the ios sdk


#cd $PROJ_PATH && xcodebuild -project Heyzap.xcodeproj/ -parallelizeTargets -configuration "Release" -target "SDK"

# Clean up the build path


# rm -rf $BUILD_PATH
# rm -rf $ADS_BUILD_PATH
# mkdir $BUILD_PATH

# cp -PR $PROJ_PATH/build/Release-iphoneos/Heyzap.framework $BUILD_PATH
# cp -R $PROJ_PATH/build/Release-iphoneos/Heyzap.bundle $BUILD_PATH
# cp -R $PROJ_PATH/build/Release-iphoneos/libHeyzap.a $BUILD_PATH
# cp -R $PROJ_PATH/build/Release-iphoneos/HeyzapHeaders/ $BUILD_PATH/Headers










# Clean the build targets

# mkdir $ADS_BUILD_PATH
# cp -PR $PROJ_PATH/build/Release-iphoneos/HeyzapAds.framework $ADS_BUILD_PATH
# cp $PROJ_PATH/build/Release-iphoneos/libHeyzapAds.a $BUILD_PATH
# cp -R $PROJ_PATH/build/Release-iphoneos/HeyzapHeaders/ $BUILD_PATH/Headers