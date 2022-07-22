#include <cmath>
#include <cstdint>
#include <cstring>
#include <exception>
#include <jni.h>
#include <vector>

#include "../exception.h"
#include "../log.h"
#include "../math_util.h"
#include "../util.h"
#include "./hslhsv.h"

using namespace plugin;
using namespace std;

namespace {

class Brightness {
public:
  std::vector<uint8_t> apply(const uint8_t *rgba8, const size_t width,
                             const size_t height, const float weight);

private:
  static constexpr const char *TAG = "Brightness";
};

} // namespace

extern "C" JNIEXPORT jbyteArray JNICALL
Java_com_nkming_nc_1photos_plugin_image_1processor_Brightness_applyNative(
    JNIEnv *env, jobject *thiz, jbyteArray rgba8, jint width, jint height,
    jfloat weight) {
  try {
    initOpenMp();
    RaiiContainer<jbyte> cRgba8(
        [&]() { return env->GetByteArrayElements(rgba8, nullptr); },
        [&](jbyte *obj) {
          env->ReleaseByteArrayElements(rgba8, obj, JNI_ABORT);
        });
    const auto result = Brightness().apply(
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

namespace {

vector<uint8_t> Brightness::apply(const uint8_t *rgba8, const size_t width,
                                  const size_t height, const float weight) {
  LOGI(TAG, "[apply] weight: %.2f", weight);
  if (weight == 0) {
    // shortcut
    return vector<uint8_t>(rgba8, rgba8 + width * height * 4);
  }

  const float mul = 1 + weight / 2;
  vector<uint8_t> output(width * height * 4);
#pragma omp parallel for
  for (size_t i = 0; i < width * height; ++i) {
    const auto p = i * 4;
    auto hsv = filter::rgb8ToHsv(rgba8 + p);
    hsv[2] = clamp(0.f, hsv[2] * mul, 1.f);
    const auto &newRgb = filter::hsvToRgb8(hsv.data());
    memcpy(output.data() + p, newRgb.data(), 3);
    output[p + 3] = rgba8[p + 3];
  }
  return output;
}

} // namespace
