#include <cstdint>
#include <exception>
#include <jni.h>
#include <vector>

#include "../exception.h"
#include "../log.h"
#include "../util.h"

using namespace plugin;
using namespace std;

namespace {

class Orientation {
public:
  std::vector<uint8_t> apply(const uint8_t *rgba8, const size_t width,
                             const size_t height, const int degree);

private:
  std::vector<uint8_t> apply90Ccw(const uint8_t *rgba8, const size_t width,
                                  const size_t height);
  std::vector<uint8_t> apply90Cw(const uint8_t *rgba8, const size_t width,
                                 const size_t height);
  std::vector<uint8_t> apply180(const uint8_t *rgba8, const size_t width,
                                const size_t height);

  static constexpr const char *TAG = "Orientation";
};

} // namespace

extern "C" JNIEXPORT jbyteArray JNICALL
Java_com_nkming_nc_1photos_plugin_image_1processor_Orientation_applyNative(
    JNIEnv *env, jobject *thiz, jbyteArray rgba8, jint width, jint height,
    jint degree) {
  try {
    initOpenMp();
    RaiiContainer<jbyte> cRgba8(
        [&]() { return env->GetByteArrayElements(rgba8, nullptr); },
        [&](jbyte *obj) {
          env->ReleaseByteArrayElements(rgba8, obj, JNI_ABORT);
        });
    const auto result = Orientation().apply(
        reinterpret_cast<uint8_t *>(cRgba8.get()), width, height, degree);
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

vector<uint8_t> Orientation::apply(const uint8_t *rgba8, const size_t width,
                                   const size_t height, const int degree) {
  LOGI(TAG, "[apply] degree: %d", degree);
  if (degree == 0) {
    // shortcut
    return vector<uint8_t>(rgba8, rgba8 + width * height * 4);
  }

  if (degree == 90) {
    return apply90Ccw(rgba8, width, height);
  } else if (degree == -90) {
    return apply90Cw(rgba8, width, height);
  } else {
    return apply180(rgba8, width, height);
  }
}

vector<uint8_t> Orientation::apply90Ccw(const uint8_t *rgba8,
                                        const size_t width,
                                        const size_t height) {
  vector<uint8_t> output(width * height * 4);
#pragma omp parallel for
  for (size_t y = 0; y < height; ++y) {
    const auto yI = y * width * 4;
    for (size_t x = 0; x < width; ++x) {
      const auto p = x * 4 + yI;
      const auto desY = width - x - 1;
      const auto desX = y;
      const auto desP = (desY * height + desX) * 4;
      output[desP + 0] = rgba8[p + 0];
      output[desP + 1] = rgba8[p + 1];
      output[desP + 2] = rgba8[p + 2];
      output[desP + 3] = rgba8[p + 3];
    }
  }
  return output;
}

vector<uint8_t> Orientation::apply90Cw(const uint8_t *rgba8, const size_t width,
                                       const size_t height) {
  vector<uint8_t> output(width * height * 4);
#pragma omp parallel for
  for (size_t y = 0; y < height; ++y) {
    const auto yI = y * width * 4;
    for (size_t x = 0; x < width; ++x) {
      const auto p = x * 4 + yI;
      const auto desY = x;
      const auto desX = height - y - 1;
      const auto desP = (desY * height + desX) * 4;
      output[desP + 0] = rgba8[p + 0];
      output[desP + 1] = rgba8[p + 1];
      output[desP + 2] = rgba8[p + 2];
      output[desP + 3] = rgba8[p + 3];
    }
  }
  return output;
}

vector<uint8_t> Orientation::apply180(const uint8_t *rgba8, const size_t width,
                                      const size_t height) {
  vector<uint8_t> output(width * height * 4);
#pragma omp parallel for
  for (size_t y = 0; y < height; ++y) {
    const auto yI = y * width * 4;
    for (size_t x = 0; x < width; ++x) {
      const auto p = x * 4 + yI;
      const auto desY = height - y - 1;
      const auto desX = width - x - 1;
      const auto desP = (desY * width + desX) * 4;
      output[desP + 0] = rgba8[p + 0];
      output[desP + 1] = rgba8[p + 1];
      output[desP + 2] = rgba8[p + 2];
      output[desP + 3] = rgba8[p + 3];
    }
  }
  return output;
}

} // namespace
