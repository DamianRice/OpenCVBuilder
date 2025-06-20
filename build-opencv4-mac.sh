#!/usr/bin/env bash
# ./build-opencv4-mac.sh -n x86_64 -c Debug
# ./build-opencv4-mac.sh -n arm64 -c Release

_list_of_build_type="Debug Release MinSizeRel RelWithDebInfo"
_list_of_arch_type="x86_64 arm64"

HOST_OS=$(uname -s)
NUM_THREADS=1
BUILD_TYPE=Release
JAVA_FLAG=""
TARGET_ARCH=""

function exists_in_list() {
    LIST=$1
    DELIMITER=$2
    VALUE=$3
    [[ "$LIST" =~ ($DELIMITER|^)$VALUE($DELIMITER|$) ]]
}

function usage(){
    echo -e "-n -c are required, -j is to build OpenCV Java
    -n: Arch [x86_64, arm64]
    -c: Build type [Debug, Release, MinSizeRel, RelWithDebInfo]
    -j: Enable Build OpenCV Java
    "
}


if [ "$HOST_OS" == "Darwin" ]; then
    NUM_THREADS=$(sysctl -n hw.ncpu)
else
    echo "Unsupported OS: $HOST_OS"
    exit 0
fi



while getopts ":n:c:j" arg; do
    case $arg in
    n)
        if exists_in_list "$_list_of_arch_type" " " "$OPTARG"; then
          echo "n(TARGET_ARCH):$OPTARG"
          TARGET_ARCH="$OPTARG"
        else
          echo "n's arg must be x86_64 or arm64, now is ${OPTARG}"
        fi

        if [ -z "$TARGET_ARCH" ]; then
            echo -e "empty TARGET_ARCH."
            echo -e "usage1: ./build-opencv3-linux.sh -n x86_64"
            echo -e "usage2: ./build-opencv3-linux.sh -n arm64"
            exit 1
        fi
        ;;

    c) 
        if exists_in_list "$_list_of_build_type" " " "$OPTARG"; then
          echo "c's arg:$OPTARG"
          BUILD_TYPE=$OPTARG
        else
          echo "c's arg must be Debug,Release,MinSizeRel or RelWithDebInfo, now is $OPTARG"
        fi
        ;;

    j)
        echo "j's arg:$OPTARG"
        JAVA_FLAG="-DBUILD_FAT_JAVA_LIB=ON -DBUILD_JAVA=ON -DBUILD_opencv_java=ON -DBUILD_opencv_flann=ON"
        ;;

    ?)
        echo -e "Unknown argument." usage && exit 1;
        ;;
    esac
done



BUILD_OUTPUT_PATH="build-MacOS-$TARGET_ARCH"
BUILD_INSTALL_PATH="$BUILD_OUTPUT_PATH/install/$BUILD_TYPE"
OPENCV_CONTRIB_DIR=realpath "../opencv_contrib/modules"

mkdir -p "$BUILD_OUTPUT_PATH"

cmake --compile-no-warning-as-error                 \
    -B"$BUILD_OUTPUT_PATH"                          \
    -DCMAKE_INSTALL_PREFIX="$BUILD_INSTALL_PATH"    \
    -DCMAKE_SYSTEM_NAME="Darwin"                    \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="10.9"            \
    -DCMAKE_SYSTEM_PROCESSOR="$TARGET_ARCH"         \
    -DCMAKE_OSX_ARCHITECTURES="$TARGET_ARCH"        \
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE                  \
    -DCMAKE_CONFIGURATION_TYPES=$BUILD_TYPE         \
    -DOPENCV_EXTRA_MODULES_PATH=$OPENCV_CONTRIB_DIR \
    $(cat opencv4_cmake_options.txt)                \
    $JAVA_FLAG

cmake --build "$BUILD_OUTPUT_PATH" --config $BUILD_TYPE --parallel $NUM_THREADS
cmake --install "$BUILD_OUTPUT_PATH" --config $BUILD_TYPE --prefix "$BUILD_INSTALL_PATH"