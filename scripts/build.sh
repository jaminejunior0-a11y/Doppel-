#!/data/data/com.termux/files/usr/bin/bash

# Configuration
JAVA_HOME=/data/data/com.termux/files/usr/lib/jvm/java-17-openjdk
ANDROID_HOME=$HOME/android-sdk
NDK=$ANDROID_HOME/ndk/23.1.7779620
BUILD_TOOLS=$ANDROID_HOME/build-tools/29.0.3
PLATFORM=$ANDROID_HOME/platforms/android-29/android.jar

export PATH=$JAVA_HOME/bin:$PATH

# Clean and create directories
rm -rf build
mkdir -p build/{classes,dex,apk,lib}

echo "1. Compiling Java without lambdas (using anonymous inner class)..."
# First, fix the Java file to not use lambdas
cat > app/src/main/java/com/doppel/MainActivity.java << 'JAVAEOF'
package com.doppel;
import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;
import android.widget.LinearLayout;
import android.widget.Button;
import android.view.View;

public class MainActivity extends Activity {
    static { System.loadLibrary("proputils"); }
    public native String getSystemProperty(String key);
    public native boolean initNative();
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(50, 50, 50, 50);
        
        TextView title = new TextView(this);
        title.setText("Doppel");
        title.setTextSize(32);
        layout.addView(title);
        
        final TextView status = new TextView(this);
        status.setText("Ready");
        status.setTextSize(16);
        layout.addView(status);
        
        Button btn = new Button(this);
        btn.setText("Test Native");
        btn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                boolean init = initNative();
                String prop = getSystemProperty("test.key");
                status.setText("Init: " + init + "\nProp: " + prop);
            }
        });
        layout.addView(btn);
        
        setContentView(layout);
    }
}
JAVAEOF

# Now compile with Java 8 compatibility
javac -source 1.7 -target 1.7 \
  -bootclasspath $PLATFORM \
  -d build/classes \
  app/src/main/java/com/doppel/*.java

if [ $? -ne 0 ]; then
    echo "Java compilation failed"
    exit 1
fi

echo "2. Converting to DEX..."
$BUILD_TOOLS/dx --dex --output=build/dex/classes.dex build/classes

if [ $? -ne 0 ]; then
    echo "DEX conversion failed"
    exit 1
fi

echo "3. Building native libraries with NDK (forcing aarch64)..."
cd app/src/main/cpp
# Create a simple Android.mk
mkdir -p jni
cat > jni/Android.mk << 'MKEOF'
LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)
LOCAL_MODULE := proputils
LOCAL_SRC_FILES := ../proputils.cpp
LOCAL_LDLIBS := -llog
include $(BUILD_SHARED_LIBRARY)
MKEOF

cat > jni/Application.mk << 'MKEOF'
APP_ABI := armeabi-v7a arm64-v8a
APP_PLATFORM := android-16
APP_STL := c++_shared
MKEOF

# Create the proputils.cpp if it doesn't exist
cat > proputils.cpp << 'CPPEOF'
#include <jni.h>
#include <android/log.h>
#define LOG_TAG "Doppel"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
extern "C" {
JNIEXPORT jstring JNICALL Java_com_doppel_MainActivity_getSystemProperty(JNIEnv* env, jobject thiz, jstring key) {
    const char* key_str = env->GetStringUTFChars(key, NULL);
    LOGI("Getting property: %s", key_str);
    env->ReleaseStringUTFChars(key, key_str);
    return env->NewStringUTF("test_value");
}
JNIEXPORT jboolean JNICALL Java_com_doppel_MainActivity_initNative(JNIEnv* env, jobject thiz) {
    LOGI("Native init called");
    return JNI_TRUE;
}
}
CPPEOF

# Build with NDK - force architecture
cd jni
$NDK/ndk-build APP_ABI=armeabi-v7a,arm64-v8a
cd ../../../..

if [ $? -ne 0 ]; then
    echo "NDK build failed"
    exit 1
fi

echo "4. Creating APK structure..."
# Copy native libs to build/lib
mkdir -p build/lib
cp -r app/src/main/cpp/jni/libs/* build/lib/ 2>/dev/null || echo "No libs to copy"

echo "5. Packaging APK..."
# Create base APK with manifest and resources
cd build
aapt p -f \
  -M ../app/src/main/AndroidManifest.xml \
  -I $PLATFORM \
  -F doppel-unsigned.apk \
  .

if [ $? -ne 0 ]; then
    echo "AAPT packaging failed"
    exit 1
fi

echo "6. Adding DEX to APK..."
aapt add doppel-unsigned.apk dex/classes.dex

echo "7. Adding native libraries to APK..."
# Add each ABI's libraries
if [ -d "lib/armeabi-v7a" ]; then
    aapt add doppel-unsigned.apk lib/armeabi-v7a/libproputils.so
fi
if [ -d "lib/arm64-v8a" ]; then
    aapt add doppel-unsigned.apk lib/arm64-v8a/libproputils.so
fi

echo "8. Aligning APK..."
zipalign -f 4 doppel-unsigned.apk doppel-aligned.apk

if [ $? -ne 0 ]; then
    echo "Zipalign failed"
    exit 1
fi

echo "9. Signing with debug key..."
cd ..
if [ ! -f debug.keystore ]; then
    keytool -genkey -v -keystore debug.keystore \
      -alias debug -keyalg RSA -keysize 2048 -validity 10000 \
      -storepass android -keypass android \
      -dname "CN=Debug, OU=Debug, O=Debug, L=Debug, ST=Debug, C=US"
fi

apksigner sign --ks debug.keystore \
  --ks-pass pass:android --key-pass pass:android \
  --min-sdk-version 16 \
  --out build/doppel-debug.apk build/doppel-aligned.apk

if [ $? -ne 0 ]; then
    echo "APK signing failed"
    exit 1
fi

echo "10. Verifying APK..."
aapt list build/doppel-debug.apk | head -20

echo "✅ APK created at build/doppel-debug.apk"
ls -la build/doppel-debug.apk
