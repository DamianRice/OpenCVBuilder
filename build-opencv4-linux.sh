#!/usr/bin/env bash
# ./build-opencv4-linux.sh -n 386
# ./build-opencv4-linux.sh -n amd64
# ./build-opencv4-linux.sh -n arm
# ./build-opencv4-linux.sh -n arm64
# ./build-opencv4-linux.sh -n ppc64le

_list_of_build_type="Debug Release"
_list_of_arch_type="386 amd64 arm arm64 ppc64le"

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
    -n: Arch [386 amd64 arm arm64 ppc64le]
    -c: Build type [Debug, Release]
    -j: Enable Build OpenCV Java
    "
}

if [ "$HOST_OS" == "Linux" ]; then
    NUM_THREADS=$(nproc)
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
          echo "n's arg must be 386 amd64 arm arm64 or ppc64le, now is ${OPTARG}"
        fi

        if [ -z "$TARGET_ARCH" ]; then
            echo -e "empty TARGET_ARCH."
            echo -e "usage: ./build-opencv3-linux.sh -n amd64"
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



# get gcc version
export _compiler=$(which gcc)
MAJOR=$(echo __GNUC__ | $_compiler -E -xc - | tail -n 1)
MINOR=$(echo __GNUC_MINOR__ | $_compiler -E -xc - | tail -n 1)
PATCH_LEVEL=$(echo __GNUC_PATCHLEVEL__ | $_compiler -E -xc - | tail -n 1)

if [ "$HOST_OS" == "Linux" ] && [ "$TARGET_ARCH" == "arm64" ] && [ "$MAJOR.$MINOR.$PATCH_LEVEL" == "4.8.4" ]; then
    echo "Linux arm64 gcc version is 4.8.4, turn off libwebp"
    DISABLE_OPTION="-DBUILD_WEBP=OFF -DWITH_WEBP=OFF"
elif [ "$HOST_OS" == "Linux" ] && [ "$TARGET_ARCH" == "386" ] && [ "$MAJOR.$MINOR.$PATCH_LEVEL" == "4.8.4" ]; then
    echo "Linux 386 gcc version is 4.8.4, turn off openexr"
    DISABLE_OPTION="-DBUILD_OPENEXR=OFF -DWITH_OPENEXR=OFF"
else
    echo "Other gcc version"
    DISABLE_OPTION=""
fi

BUILD_OUTPUT_PATH="build-Linux-$BUILD_TYPE-$TARGET_ARCH"
BUILD_INSTALL_PATH="$BUILD_OUTPUT_PATH/install/$BUILD_TYPE"
OPENCV_CONTRIB_DIR=realpath "../opencv_contrib/modules"

mkdir -p "$BUILD_OUTPUT_PATH"

cmake --compile-no-warning-as-error                 \
    -B"$BUILD_OUTPUT_PATH"                          \
    -DCMAKE_INSTALL_PREFIX="$BUILD_INSTALL_PATH"    \
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE                  \
    -DCMAKE_CONFIGURATION_TYPES=$BUILD_TYPE         \
    -DOPENCV_EXTRA_MODULES_PATH=$OPENCV_CONTRIB_DIR \
    $(cat opencv4_cmake_options.txt)                \
    $DISABLE_OPTION                                 \
    $JAVA_FLAG

cmake --build "$BUILD_OUTPUT_PATH" --config $BUILD_TYPE --parallel $NUM_THREADS
cmake --install "$BUILD_OUTPUT_PATH" --config $BUILD_TYPE --prefix "$BUILD_INSTALL_PATH"
