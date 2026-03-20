#include <jni.h>
#include <android/log.h>
#include <cstring>
#include <cstdlib>

#define LOG_TAG "DoppelNative"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

// Mock property storage for demo
static const char* mock_props[][2] = {
    {"ro.product.model", "Doppel Phantom"},
    {"ro.product.manufacturer", "Doppel Labs"},
    {"ro.build.version.release", "99.9.9"},
    {"ro.product.name", "doppel_phantom"},
    {"ro.serialno", "DOPPEL1337"},
    {NULL, NULL}
};

extern "C" {

JNIEXPORT jstring JNICALL
Java_com_doppel_MainActivity_getSystemProperty(JNIEnv* env, jobject thiz, jstring key) {
    const char* key_str = env->GetStringUTFChars(key, NULL);
    LOGI("Getting system property: %s", key_str);
    
    // Check mock props first
    for (int i = 0; mock_props[i][0] != NULL; i++) {
        if (strcmp(key_str, mock_props[i][0]) == 0) {
            env->ReleaseStringUTFChars(key, key_str);
            LOGI("Returning mock value: %s", mock_props[i][1]);
            return env->NewStringUTF(mock_props[i][1]);
        }
    }
    
    // In real implementation, this would call __system_property_get
    // For demo, return key as value
    env->ReleaseStringUTFChars(key, key_str);
    return env->NewStringUTF("real_value_unknown");
}

JNIEXPORT jboolean JNICALL
Java_com_doppel_MainActivity_initNative(JNIEnv* env, jobject thiz) {
    LOGI("Doppel native library initialized with mock support");
    return JNI_TRUE;
}

JNIEXPORT jstring JNICALL
Java_com_doppel_MainActivity_getPropHook(JNIEnv* env, jobject thiz, jstring key) {
    const char* key_str = env->GetStringUTFChars(key, NULL);
    LOGI("Hook called for: %s", key_str);
    
    // Always return mock value when hooked
    env->ReleaseStringUTFChars(key, key_str);
    return env->NewStringUTF("DOppel_HOOKED_VALUE");
}

}
