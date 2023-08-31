#include <cstdint>
#include <exception>
#include <jni.h>

#include "../core/filter/filters.h"
#include "../exception.h"
#include "../util.h"

using namespace core;
using namespace im_proc;
using namespace std;

extern "C" JNIEXPORT jbyteArray JNICALL
Java_com_nkming_nc_1photos_np_1platform_1image_1processor_processor_Warmth_applyNative(
    JNIEnv *env, jobject *thiz, jbyteArray rgba8, jint width, jint height,
    jfloat weight) {
  try {
    initOpenMp();
    RaiiContainer<jbyte> cRgba8(
        [&]() { return env->GetByteArrayElements(rgba8, nullptr); },
        [&](jbyte *obj) {
          env->ReleaseByteArrayElements(rgba8, obj, JNI_ABORT);
        });
    const auto result = filter::applyWarmth(
        reinterpret_cast<uint8_t *>(cRgba8.get()), width, height, weight);
    auto resultAry = env->NewByteArray(result.size());
    env->SetByteArrayRegion(resultAry, 0, result.size(),
                            reinterpret_cast<const int8_t *>(result.data()));
    return resultAry;
  } catch (const exception &e) {
    throwJavaException(env, e.what());
    return nullptr;
  }
}
