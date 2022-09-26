#include "exception.h"
#include "lib/base_resample.h"
#include "log.h"
#include "stopwatch.h"
#include "tflite_wrapper.h"
#include "util.h"
#include <algorithm>
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>
#include <cassert>
#include <exception>
#include <jni.h>
#include <tensorflow/lite/c/c_api.h>
#include <tensorflow/lite/delegates/gpu/delegate.h>

using namespace plugin;
using namespace std;
using namespace tflite;

namespace {

constexpr const char *MODEL = "tf/zero_dce_lite_200x300_iter8_60.tflite";
constexpr size_t WIDTH = 300;
constexpr size_t HEIGHT = 200;

class ZeroDce {
public:
  explicit ZeroDce(AAssetManager *const aam);

  std::vector<uint8_t> infer(const uint8_t *image, const size_t width,
                             const size_t height, const unsigned iteration);

private:
  std::vector<uint8_t> inferAlphaMaps(const uint8_t *image, const size_t width,
                                      const size_t height);
  std::vector<uint8_t> enhance(const uint8_t *image, const size_t width,
                               const size_t height,
                               const std::vector<uint8_t> &alphaMaps,
                               const unsigned iteration);

  Model model;

  static constexpr const char *TAG = "ZeroDce";
};

} // namespace

extern "C" JNIEXPORT jbyteArray JNICALL
Java_com_nkming_nc_1photos_plugin_image_1processor_ZeroDce_inferNative(
    JNIEnv *env, jobject *thiz, jobject assetManager, jbyteArray image,
    jint width, jint height, jint iteration) {
  try {
    initOpenMp();
    auto aam = AAssetManager_fromJava(env, assetManager);
    ZeroDce model(aam);
    RaiiContainer<jbyte> cImage(
        [&]() { return env->GetByteArrayElements(image, nullptr); },
        [&](jbyte *obj) {
          env->ReleaseByteArrayElements(image, obj, JNI_ABORT);
        });
    const auto result = model.infer(reinterpret_cast<uint8_t *>(cImage.get()),
                                    width, height, iteration);
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

ZeroDce::ZeroDce(AAssetManager *const aam) : model(Asset(aam, MODEL)) {}

vector<uint8_t> ZeroDce::infer(const uint8_t *image, const size_t width,
                               const size_t height, const unsigned iteration) {
  const auto alphaMaps = inferAlphaMaps(image, width, height);
  return enhance(image, width, height, alphaMaps, iteration);
}

vector<uint8_t> ZeroDce::inferAlphaMaps(const uint8_t *image,
                                        const size_t width,
                                        const size_t height) {
  InterpreterOptions options;
  options.setNumThreads(getNumberOfProcessors());

  auto gpuOptions = TfLiteGpuDelegateOptionsV2Default();
  auto gpuDelegate = AutoTfLiteDelegate(TfLiteGpuDelegateV2Create(&gpuOptions));
  options.addDelegate(gpuDelegate.get());

  Interpreter interpreter(model, options);
  interpreter.allocateTensors();

  LOGI(TAG, "[inferAlphaMaps] Convert bitmap to input");
  vector<uint8_t> inputBitmap(WIDTH * HEIGHT * 3);
  base::ResampleImage24(image, width, height, inputBitmap.data(), WIDTH, HEIGHT,
                        base::KernelTypeLanczos3);
  const auto input =
      rgb8ToRgbFloat(inputBitmap.data(), inputBitmap.size(), true);
  auto inputTensor = interpreter.getInputTensor(0);
  assert(TfLiteTensorByteSize(inputTensor) == input.size() * sizeof(float));
  TfLiteTensorCopyFromBuffer(inputTensor, input.data(),
                             input.size() * sizeof(float));

  LOGI(TAG, "[inferAlphaMaps] Inferring");
  Stopwatch stopwatch;
  interpreter.invoke();
  LOGI(TAG, "[inferAlphaMaps] Elapsed: %.3fs", stopwatch.getMs() / 1000.0f);

  auto outputTensor = interpreter.getOutputTensor(1);
  vector<float> output(input.size());
  assert(TfLiteTensorByteSize(outputTensor) == output.size() * sizeof(float));
  TfLiteTensorCopyToBuffer(outputTensor, output.data(),
                           output.size() * sizeof(float));
  // the output is in negative, we need to abs them
  for (size_t i = 0; i < output.size(); ++i) {
    output[i] = fabsf(output[i]);
  }
  return rgbFloatToRgb8(output.data(), output.size(), true);
}

vector<uint8_t> ZeroDce::enhance(const uint8_t *image, const size_t width,
                                 const size_t height,
                                 const vector<uint8_t> &alphaMaps,
                                 const unsigned iteration) {
  LOGI(TAG, "[enhance] Enhancing image, iteration: %d", iteration);
  // resize aMaps
  vector<uint8_t> filter(width * height * 3);
  base::ResampleImage24(alphaMaps.data(), WIDTH, HEIGHT, filter.data(), width,
                        height, base::KernelTypeBicubic);

  vector<uint8_t> output(width * height * 3);
#pragma omp parallel for
  for (size_t i = 0; i < filter.size(); ++i) {
    auto s = image[i] / 255.0f;
    const auto f = filter[i] / 255.0f;
    for (unsigned j = 0; j < iteration; ++j) {
      s += -f * (std::pow(s, 2.0f) - s);
    }
    output[i] = std::max(0, std::min(static_cast<int>(s * 255), 255));
  }
  return output;
}

} // namespace
