#pragma once

#include <jni.h>

void throwJavaException(JNIEnv *env, const char *msg);
