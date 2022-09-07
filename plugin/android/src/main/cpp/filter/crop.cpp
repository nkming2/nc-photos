#include <cstdint>
#include <cstring>
#include <exception>
#include <jni.h>
#include <vector>

#include "../exception.h"
#include "../log.h"
#include "../util.h"

using namespace plugin;
using namespace std;

namespace {

class Crop {
public:
  std::vector<uint8_t> apply(const uint8_t *rgba8, const size_t width,
                             const size_t height, const int top, const int left,
                             const int dstWidth, const int dstHeight);

private:
  static constexpr const char *TAG = "Crop";
};

} // namespace

extern "C" JNIEXPORT jbyteArray JNICALL
Java_com_nkming_nc_1photos_plugin_image_1processor_Crop_applyNative(
    JNIEnv *env, jobject *thiz, jbyteArray rgba8, jint width, jint height,
    jint top, jint left, jint dstWidth, jint dstHeight) {
  try {
    initOpenMp();
    RaiiContainer<jbyte> cRgba8(
        [&]() { return env->GetByteArrayElements(rgba8, nullptr); },
        [&](jbyte *obj) {
          env->ReleaseByteArrayElements(rgba8, obj, JNI_ABORT);
        });
    const auto result =
        Crop().apply(reinterpret_cast<uint8_t *>(cRgba8.get()), width, height,
                     top, left, dstWidth, dstHeight);
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

vector<uint8_t> Crop::apply(const uint8_t *rgba8, const size_t width,
                            const size_t height, const int top, const int left,
                            const int dstWidth, const int dstHeight) {
  LOGI(TAG, "[apply] top: %d, left: %d, width: %d, height: %d", top, left,
       dstWidth, dstHeight);
  vector<uint8_t> output(dstWidth * dstHeight * 4);
#pragma omp parallel for
  for (size_t y = 0; y < dstHeight; ++y) {
    const auto srcY = y + top;
    memcpy(output.data() + (y * dstWidth * 4),
           rgba8 + (srcY * width + left) * 4, dstWidth * 4);
  }
  return output;
}

} // namespace
