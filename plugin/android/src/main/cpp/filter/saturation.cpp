#include <cmath>
#include <cstdint>
#include <cstring>
#include <exception>
#include <jni.h>
#include <memory>
#include <vector>

#include "../exception.h"
#include "../log.h"
#include "../math_util.h"
#include "../util.h"
#include "./hslhsv.h"
#include "./saturation.h"

using namespace plugin;
using namespace std;

extern "C" JNIEXPORT jbyteArray JNICALL
Java_com_nkming_nc_1photos_plugin_image_1processor_Saturation_applyNative(
    JNIEnv *env, jobject *thiz, jbyteArray rgba8, jint width, jint height,
    jfloat value) {
  try {
    initOpenMp();
    RaiiContainer<jbyte> cRgba8(
        [&]() { return env->GetByteArrayElements(rgba8, nullptr); },
        [&](jbyte *obj) {
          env->ReleaseByteArrayElements(rgba8, obj, JNI_ABORT);
        });
    const auto result = filter::Saturation().apply(
        reinterpret_cast<uint8_t *>(cRgba8.get()), width, height, value);
    auto resultAry = env->NewByteArray(result.size());
    env->SetByteArrayRegion(resultAry, 0, result.size(),
                            reinterpret_cast<const int8_t *>(result.data()));
    return resultAry;
  } catch (const exception &e) {
    throwJavaException(env, e.what());
    return nullptr;
  }
}

namespace plugin {
namespace filter {

vector<uint8_t> Saturation::apply(const uint8_t *rgba8, const size_t width,
                                  const size_t height, const float weight) {
  LOGI(TAG, "[apply] weight: %.2f", weight);
  if (weight == 0) {
    // shortcut
    return vector<uint8_t>(rgba8, rgba8 + width * height * 4);
  }

  vector<uint8_t> output(width * height * 4);
#pragma omp parallel for
  for (size_t i = 0; i < width * height; ++i) {
    const auto p = i * 4;
    auto hsl = filter::rgb8ToHsl(rgba8 + p);
    hsl[1] = clamp(0.f, hsl[1] * (1 + weight), 1.f);
    const auto &newRgb = filter::hslToRgb8(hsl.data());
    memcpy(output.data() + p, newRgb.data(), 3);
    output[p + 3] = rgba8[p + 3];
  }
  return output;
}

} // namespace
}
