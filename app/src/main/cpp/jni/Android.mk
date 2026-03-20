LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := proputils
LOCAL_SRC_FILES := ../proputils.cpp
LOCAL_LDLIBS := -llog
include $(BUILD_SHARED_LIBRARY)
