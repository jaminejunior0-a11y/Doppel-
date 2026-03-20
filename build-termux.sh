#!/data/data/com.termux/files/usr/bin/bash

set -e
echo "🔧 Doppel Termux-Native Build"
echo "=============================="

# Configuration
JAVA_HOME=/data/data/com.termux/files/usr/lib/jvm/java-17-openjdk
ANDROID_HOME=$HOME/android-sdk
PLATFORM=$ANDROID_HOME/platforms/android-29/android.jar
BUILD_TOOLS=$ANDROID_HOME/build-tools/29.0.3

export PATH=$JAVA_HOME/bin:$PATH

# Clean
rm -rf build
mkdir -p build/{classes,dex,apk,lib/arm64-v8a}

echo "✅ Directories created"

# Find all Java files recursively
JAVA_FILES=$(find app/src/main/java -name "*.java")
echo "📝 Found Java files:"
echo "$JAVA_FILES"

# Step 1: Compile Java
echo "📝 Step 1: Compiling Java..."
javac -source 1.7 -target 1.7 \
  -bootclasspath $PLATFORM \
  -d build/classes \
  $JAVA_FILES

if [ $? -ne 0 ]; then
    echo "❌ Java compilation failed"
    exit 1
fi
echo "✅ Java compilation complete"

# Step 2: Convert to DEX
echo "📝 Step 2: Converting to DEX..."
$BUILD_TOOLS/dx --dex --output=build/dex/classes.dex build/classes

echo "✅ DEX conversion complete"

# Step 3: Compile native library
echo "📝 Step 3: Compiling native library..."
clang++ \
  -target aarch64-linux-android21 \
  -fPIC -shared \
  -o build/lib/arm64-v8a/libproputils.so \
  app/src/main/cpp/proputils.cpp \
  -llog

file build/lib/arm64-v8a/libproputils.so
echo "✅ Native compilation complete"

# Step 4: Package APK
echo "📝 Step 4: Packaging APK..."
cd build

# Create unsigned APK
aapt package -f \
  -M ../app/src/main/AndroidManifest.xml \
  -S ../app/src/main/res \
  -I $PLATFORM \
  -F doppel-unsigned.apk

# Add DEX file
aapt add doppel-unsigned.apk dex/classes.dex

# Add native library
aapt add doppel-unsigned.apk lib/arm64-v8a/libproputils.so

echo "✅ APK packaged"

# Step 5: Align APK
echo "📝 Step 5: Aligning APK..."
zipalign -f 4 doppel-unsigned.apk doppel-aligned.apk

echo "✅ APK aligned"

# Step 6: Sign APK
echo "📝 Step 6: Signing APK..."
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

# Step 7: Verify
echo "📝 Step 7: Verifying APK..."
aapt list build/doppel-debug.apk

echo ""
echo "🎉 Build successful! APK location: $(pwd)/build/doppel-debug.apk"
ls -la build/doppel-debug.apk

# Copy to Downloads for easy access
cp build/doppel-debug.apk /sdcard/Download/ 2>/dev/null || echo "Note: Couldn't copy to Downloads"
echo "📱 APK also available at: /sdcard/Download/doppel-debug.apk"
