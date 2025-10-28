# Quick Setup Commands for Qt Creator

## Option 1: Add to CMake Arguments in Qt Creator

Go to: Projects → Android Qt 6.10.0 Clang arm64-v8a → Build Settings → CMake

Add this line to "Initial Configuration":

```
OpenCV_DIR:PATH=/home/hungkv/Android/OpenCV-android-sdk/sdk/native/jni/abi-arm64-v8a
```

## Option 2: Command Line Build

```bash
cd /home/hungkv/projects/file_transfer_ovimage
mkdir -p build/Android_arm64_manual
cd build/Android_arm64_manual

cmake ../.. \
  -DCMAKE_TOOLCHAIN_FILE=/home/hungkv/Android/Sdk/ndk/27.2.12479018/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-23 \
  -DANDROID_NDK=/home/hungkv/Android/Sdk/ndk/27.2.12479018 \
  -DANDROID_STL=c++_shared \
  -DQt6_DIR=/home/hungkv/Qt/6.10.0/android_arm64_v8a/lib/cmake/Qt6 \
  -DOpenCV_DIR=/home/hungkv/Android/OpenCV-android-sdk/sdk/native/jni/abi-arm64-v8a \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH

cmake --build . -j$(nproc)
```

## Option 3: Set Environment Variable

In Qt Creator:
Projects → Android Qt 6.10.0 Clang arm64-v8a → Build Environment

Add:
- Name: `OpenCV_DIR`
- Value: `/home/hungkv/Android/OpenCV-android-sdk/sdk/native/jni/abi-arm64-v8a`

## Verify Setup

After configuration, check CMake output for:

```
-- Android build detected
-- OpenCV_DIR: /home/hungkv/Android/OpenCV-android-sdk/sdk/native/jni/abi-arm64-v8a
-- ANDROID_ABI: arm64-v8a
-- Found OpenCV: 4.10.0 (found suitable version "4.10.0", minimum required is "4.10.0")
```

## Clean and Reconfigure

If you need to start fresh:

```bash
cd /home/hungkv/projects/file_transfer_ovimage
rm -rf build/Android_Qt_6_10_0_Clang_arm64_v8a-Debug/*
```

Then in Qt Creator:
- Right-click project → "Run CMake"
