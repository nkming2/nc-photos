#pragma once

#include <jni.h>

#ifdef __cplusplus
extern "C" {
#endif

JNIEXPORT jbyteArray JNICALL
Java_com_nkming_nc_1photos_plugin_image_1processor_Esrgan_inferNative(
    JNIEnv *env, jobject *thiz, jobject assetManager, jbyteArray image,
    jint width, jint height);

#ifdef __cplusplus
}
#endif
