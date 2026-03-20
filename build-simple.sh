#!/data/data/com.termux/files/usr/bin/bash

# Configuration
JAVA_HOME=/data/data/com.termux/files/usr/lib/jvm/java-17-openjdk
ANDROID_HOME=$HOME/android-sdk
NDK=$ANDROID_HOME/ndk/23.1.7779620
PLATFORM=$ANDROID_HOME/platforms/android-29/android.jar

export PATH=$JAVA_HOME/bin:$PATH

# Clean
rm -rf build
mkdir -p build/{classes,dex,lib}

echo "=== Step 1: Compile Java ==="
javac -source 1.7 -target 1.7 \
  -bootclasspath $PLATFORM \
  -d build/classes \
  app/src/main/java/com/doppel/*.java

echo "=== Step 2: Convert to DEX ==="
$ANDROID_HOME/build-tools/29.0.3/dx --dex --output=build/dex/classes.dex build/classes

echo "=== Step 3: Build Native Libraries ==="
cd app/src/main/cpp/jni
$NDK/ndk-build
cd ../../../..

# Copy native libs to build/lib
if [ -d "app/src/main/cpp/jni/libs" ]; then
    cp -r app/src/main/cpp/jni/libs/* build/lib/ 2>/dev/null || true
fi

echo "=== Step 4: Package APK ==="
cd build

# Create APK with aapt
aapt package -f \
  -M ../app/src/main/AndroidManifest.xml \
  -S ../app/src/main/res \
  -I $PLATFORM \
  -F doppel-unsigned.apk

if [ $? -ne 0 ]; then
    echo "AAPT packaging failed - trying without resources"
    aapt package -f \
      -M ../app/src/main/AndroidManifest.xml \
      -I $PLATFORM \
      -F doppel-unsigned.apk
fi

echo "=== Step 5: Add DEX to APK ==="
aapt add doppel-unsigned.apk dex/classes.dex

echo "=== Step 6: Add Native Libraries ==="
for abi in armeabi-v7a arm64-v8a; do
    if [ -f "lib/$abi/libproputils.so" ]; then
        aapt add doppel-unsigned.apk lib/$abi/libproputils.so
    fi
done

echo "=== Step 7: Align APK ==="
zipalign -f 4 doppel-unsigned.apk doppel-aligned.apk

echo "=== Step 8: Sign APK ==="
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

echo "=== Step 9: Verify APK ==="
aapt list build/doppel-debug.apk | grep -E "lib/.*\.so|classes.dex|AndroidManifest.xml"

echo ""
echo "✅ Build complete! APK location: $(pwd)/build/doppel-debug.apk"
ls -la build/doppel-debug.apk
