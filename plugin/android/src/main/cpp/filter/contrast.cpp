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

using namespace plugin;
using namespace std;

namespace {

class Contrast {
public:
  std::vector<uint8_t> apply(const uint8_t *rgba8, const size_t width,
                             const size_t height, const float weight);

private:
  static constexpr const char *TAG = "Contrast";
};

inline uint8_t applySingle(const uint8_t p, const float mul) {
  return clamp(0, static_cast<int>((p - 127) * mul + 127), 0xFF);
}

std::vector<uint8_t> buildLut(const float mul);

} // namespace

extern "C" JNIEXPORT jbyteArray JNICALL
Java_com_nkming_nc_1photos_plugin_image_1processor_Contrast_applyNative(
    JNIEnv *env, jobject *thiz, jbyteArray rgba8, jint width, jint height,
    jfloat weight) {
  try {
    initOpenMp();
    RaiiContainer<jbyte> cRgba8(
        [&]() { return env->GetByteArrayElements(rgba8, nullptr); },
        [&](jbyte *obj) {
          env->ReleaseByteArrayElements(rgba8, obj, JNI_ABORT);
        });
    const auto result = Contrast().apply(
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

vector<uint8_t> Contrast::apply(const uint8_t *rgba8, const size_t width,
                                const size_t height, const float weight) {
  LOGI(TAG, "[apply] weight: %.2f", weight);
  if (weight == 0) {
    // shortcut
    return vector<uint8_t>(rgba8, rgba8 + width * height * 4);
  }

  const float mul = weight >= 0 ? weight + 1 : (weight + 1) * .4f + .6f;
  const auto lut = buildLut(mul);
  vector<uint8_t> output(width * height * 4);
#pragma omp parallel for
  for (size_t i = 0; i < width * height; ++i) {
    const auto p = i * 4;
    output[p + 0] = lut[rgba8[p + 0]];
    output[p + 1] = lut[rgba8[p + 1]];
    output[p + 2] = lut[rgba8[p + 2]];
    output[p + 3] = rgba8[p + 3];
  }
  return output;
}

vector<uint8_t> buildLut(const float mul) {
  vector<uint8_t> product(256);
#pragma omp parallel for
  for (size_t i = 0; i < 256; ++i) {
    product[i] = applySingle(i, mul);
  }
  return product;
}

} // namespace
