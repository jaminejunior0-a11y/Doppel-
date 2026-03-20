#!/data/data/com.termux/files/usr/bin/bash

set -e  # Exit on error

echo "🔧 Doppel Build Script"
echo "======================"

# Configuration
JAVA_HOME=/data/data/com.termux/files/usr/lib/jvm/java-17-openjdk
ANDROID_HOME=$HOME/android-sdk
NDK=$ANDROID_HOME/ndk/23.1.7779620
PLATFORM=$ANDROID_HOME/platforms/android-29/android.jar
BUILD_TOOLS=$ANDROID_HOME/build-tools/29.0.3

export PATH=$JAVA_HOME/bin:$PATH

# Clean everything
rm -rf build
mkdir -p build/{classes,dex,apk,lib/{armeabi-v7a,arm64-v8a}}

echo "✅ Directories created"

# Step 1: Compile Java
echo "📝 Step 1: Compiling Java..."
javac -source 1.7 -target 1.7 \
  -bootclasspath $PLATFORM \
  -d build/classes \
  app/src/main/java/com/doppel/MainActivity.java

echo "✅ Java compilation complete"

# Step 2: Convert to DEX
echo "📝 Step 2: Converting to DEX..."
$BUILD_TOOLS/dx --dex --output=build/dex/classes.dex build/classes

echo "✅ DEX conversion complete"

# Step 3: Compile native code manually (bypass NDK's architecture detection)
echo "📝 Step 3: Compiling native libraries..."

# Create toolchain paths
TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64
if [ ! -d "$TOOLCHAIN" ]; then
    # Try alternative path
    TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-aarch64
fi

# For armeabi-v7a
echo "  Building for armeabi-v7a..."
$TOOLCHAIN/bin/armv7a-linux-androideabi16-clang++ \
  -I$NDK/sysroot/usr/include \
  -I$NDK/sysroot/usr/include/arm-linux-androideabi \
  -c app/src/main/cpp/proputils.cpp \
  -o build/armeabi-v7a.o \
  -fPIC

$TOOLCHAIN/bin/arm-linux-androideabi-ld \
  -shared \
  build/armeabi-v7a.o \
  -llog \
  -lc \
  -lm \
  -o build/lib/armeabi-v7a/libproputils.so

# For arm64-v8a
echo "  Building for arm64-v8a..."
$TOOLCHAIN/bin/aarch64-linux-android21-clang++ \
  -I$NDK/sysroot/usr/include \
  -I$NDK/sysroot/usr/include/aarch64-linux-android \
  -c app/src/main/cpp/proputils.cpp \
  -o build/arm64-v8a.o \
  -fPIC

$TOOLCHAIN/bin/aarch64-linux-android-ld \
  -shared \
  build/arm64-v8a.o \
  -llog \
  -lc \
  -lm \
  -o build/lib/arm64-v8a/libproputils.so

echo "✅ Native compilation complete"

# Step 4: Create APK structure
echo "📝 Step 4: Creating APK structure..."
mkdir -p build/apk
cp -r build/lib build/apk/
mkdir -p build/apk/res

echo "✅ APK structure created"

# Step 5: Package APK
echo "📝 Step 5: Packaging APK..."
cd build

# Create unsigned APK
aapt package -f \
  -M ../app/src/main/AndroidManifest.xml \
  -I $PLATFORM \
  -F doppel-unsigned.apk

# Add DEX file
aapt add doppel-unsigned.apk dex/classes.dex

# Add native libraries
for abi in armeabi-v7a arm64-v8a; do
    if [ -f "lib/$abi/libproputils.so" ]; then
        aapt add doppel-unsigned.apk lib/$abi/libproputils.so
    fi
done

echo "✅ APK packaged"

# Step 6: Align APK
echo "📝 Step 6: Aligning APK..."
zipalign -f 4 doppel-unsigned.apk doppel-aligned.apk

echo "✅ APK aligned"

# Step 7: Sign APK
echo "📝 Step 7: Signing APK..."
cd ..
if [ ! -f debug.keystore ]; then
    keytool -genkey -v -keystore debug.keystore \
      -alias debug -keyalg RSA -keysize 2048 -validity 10000 \
      -storepass android -keypass android \
      -dname "CN=Debug, OU=Debug, O=Debug, L=Debug, ST=Debug, C=US"
fi

apksigner sign --ks debug.keystore \
  --ks-pass pass:android \
  --key-pass pass:android \
  --min-sdk-version 16 \
  --out build/doppel-debug.apk \
  build/doppel-aligned.apk

echo "✅ APK signed"

# Step 8: Verify
echo "📝 Step 8: Verifying APK..."
aapt list build/doppel-debug.apk

echo ""
echo "🎉 Build successful! APK location: $(pwd)/build/doppel-debug.apk"
ls -la build/doppel-debug.apk
