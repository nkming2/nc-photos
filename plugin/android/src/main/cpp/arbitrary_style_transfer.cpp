#include "exception.h"
#include "lib/base_resample.h"
#include "log.h"
#include "stopwatch.h"
#include "tflite_wrapper.h"
#include "util.h"
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>
#include <cassert>
#include <cstddef>
#include <cstdint>
#include <exception>
#include <jni.h>
#include <tensorflow/lite/c/c_api.h>
#include <tensorflow/lite/delegates/gpu/delegate.h>
#include <vector>

using namespace plugin;
using namespace std;
using namespace tflite;

namespace {

constexpr const char *PREDICT_MODEL =
    "tf/arbitrary-style-transfer-inceptionv3_dr_predict_1.tflite";
constexpr const char *TRANSFER_MODEL =
    "tf/arbitrary-style-transfer-inceptionv3_dr_transfer_1.tflite";

class ArbitraryStyleTransfer {
public:
  explicit ArbitraryStyleTransfer(AAssetManager *const aam);

  std::vector<uint8_t> infer(const uint8_t *image, const size_t width,
                             const size_t height, const uint8_t *style,
                             const float weight);

private:
  std::vector<float> predict(const uint8_t *image, const size_t width,
                             const size_t height, const uint8_t *style,
                             const float weight);
  std::vector<uint8_t> transfer(const uint8_t *image, const size_t width,
                                const size_t height,
                                const std::vector<float> &bottleneck);

  /**
   * @param style The style image MUST be 256*256
   */
  std::vector<float> predictStyle(const uint8_t *style);

  std::vector<float> blendBottleneck(const std::vector<float> &style,
                                     const std::vector<float> &image,
                                     const float styleWeight);

  Model predictModel;
  Model transferModel;

  static constexpr const char *TAG = "ArbitraryStyleTransfer";
};

} // namespace

extern "C" JNIEXPORT jbyteArray JNICALL
Java_com_nkming_nc_1photos_plugin_image_1processor_ArbitraryStyleTransfer_inferNative(
    JNIEnv *env, jobject *thiz, jobject assetManager, jbyteArray image,
    jint width, jint height, jbyteArray style, jfloat weight) {
  try {
    initOpenMp();
    auto aam = AAssetManager_fromJava(env, assetManager);
    ArbitraryStyleTransfer model(aam);
    RaiiContainer<jbyte> cImage(
        [&]() { return env->GetByteArrayElements(image, nullptr); },
        [&](jbyte *obj) {
          env->ReleaseByteArrayElements(image, obj, JNI_ABORT);
        });
    RaiiContainer<jbyte> cStyle(
        [&]() { return env->GetByteArrayElements(style, nullptr); },
        [&](jbyte *obj) {
          env->ReleaseByteArrayElements(style, obj, JNI_ABORT);
        });
    const auto result =
        model.infer(reinterpret_cast<uint8_t *>(cImage.get()), width, height,
                    reinterpret_cast<uint8_t *>(cStyle.get()), weight);
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

ArbitraryStyleTransfer::ArbitraryStyleTransfer(AAssetManager *const aam)
    : predictModel(Asset(aam, PREDICT_MODEL)),
      transferModel(Asset(aam, TRANSFER_MODEL)) {}

vector<uint8_t> ArbitraryStyleTransfer::infer(const uint8_t *image,
                                              const size_t width,
                                              const size_t height,
                                              const uint8_t *style,
                                              const float weight) {
  const auto bottleneck = predict(image, width, height, style, weight);
  return transfer(image, width, height, bottleneck);
}

vector<float> ArbitraryStyleTransfer::predict(const uint8_t *image,
                                              const size_t width,
                                              const size_t height,
                                              const uint8_t *style,
                                              const float weight) {
  auto style_bottleneck = predictStyle(style);
  vector<uint8_t> imageStyleBitmap(256 * 256 * 3);
  base::ResampleImage24(image, width, height, imageStyleBitmap.data(), 256, 256,
                        base::KernelTypeLanczos3);
  auto image_bottleneck = predictStyle(imageStyleBitmap.data());
  return blendBottleneck(style_bottleneck, image_bottleneck, weight);
}

vector<uint8_t>
ArbitraryStyleTransfer::transfer(const uint8_t *image, const size_t width,
                                 const size_t height,
                                 const vector<float> &bottleneck) {
  vector<uint8_t> resizedImage;
  auto inputWidth = width;
  auto inputHeight = height;
  const uint8_t *inputImage = image;
  if (width % 4 != 0 || height % 4 != 0) {
    LOGI(TAG, "[transfer] Resize bitmap to multiple of 4");
    inputWidth = width - width % 4;
    inputHeight = height - height % 4;
    resizedImage.resize(inputWidth * inputHeight * 3);
    base::ResampleImage24(image, width, height, resizedImage.data(), inputWidth,
                          inputHeight, base::KernelTypeLanczos3);
    inputImage = resizedImage.data();
  }

  InterpreterOptions options;
  options.setNumThreads(getNumberOfProcessors());
  Interpreter interpreter(transferModel, options);
  const int dims[] = {1, static_cast<int>(inputHeight),
                      static_cast<int>(inputWidth), 3};
  interpreter.resizeInputTensor(1, dims, 4);
  interpreter.allocateTensors();

  LOGI(TAG, "[transfer] Copy bias");
  auto inputTensor0 = interpreter.getInputTensor(0);
  assert(TfLiteTensorByteSize(inputTensor0) ==
         bottleneck.size() * sizeof(float));
  TfLiteTensorCopyFromBuffer(inputTensor0, bottleneck.data(),
                             bottleneck.size() * sizeof(float));

  LOGI(TAG, "[transfer] Convert bitmap to input");
  auto input = rgb8ToRgbFloat(inputImage, inputWidth * inputHeight * 3, true);
  auto inputTensor1 = interpreter.getInputTensor(1);
  assert(TfLiteTensorByteSize(inputTensor1) == input.size() * sizeof(float));
  TfLiteTensorCopyFromBuffer(inputTensor1, input.data(),
                             input.size() * sizeof(float));
  input.clear();

  LOGI(TAG, "[transfer] Inferring");
  Stopwatch stopwatch;
  interpreter.invoke();
  LOGI(TAG, "[transfer] Elapsed: %.3fs", stopwatch.getMs() / 1000.0f);

  auto outputTensor = interpreter.getOutputTensor(0);
  vector<float> output(inputWidth * inputHeight * 3);
  assert(TfLiteTensorByteSize(outputTensor) == output.size() * sizeof(float));
  TfLiteTensorCopyToBuffer(outputTensor, output.data(),
                           output.size() * sizeof(float));
  auto outputRgb8 = rgbFloatToRgb8(output.data(), output.size(), true);
  output.clear();
  if (!resizedImage.empty()) {
    // resize it back to the original resolution
    vector<uint8_t> temp(width * height * 3);
    base::ResampleImage24(outputRgb8.data(), inputWidth, inputHeight,
                          temp.data(), width, height, base::KernelTypeBicubic);
    return temp;
  } else {
    return outputRgb8;
  }
}

vector<float> ArbitraryStyleTransfer::predictStyle(const uint8_t *style) {
  InterpreterOptions options;
  options.setNumThreads(getNumberOfProcessors());

  auto gpuOptions = TfLiteGpuDelegateOptionsV2Default();
  auto gpuDelegate = AutoTfLiteDelegate(TfLiteGpuDelegateV2Create(&gpuOptions));
  options.addDelegate(gpuDelegate.get());

  Interpreter interpreter(predictModel, options);
  interpreter.allocateTensors();

  LOGI(TAG, "[predictStyle] Convert bitmap to input");
  const auto input = rgb8ToRgbFloat(style, 256 * 256 * 3, true);
  auto inputTensor = interpreter.getInputTensor(0);
  assert(TfLiteTensorByteSize(inputTensor) == input.size() * sizeof(float));
  TfLiteTensorCopyFromBuffer(inputTensor, input.data(),
                             input.size() * sizeof(float));

  LOGI(TAG, "[predictStyle] Inferring");
  Stopwatch stopwatch;
  interpreter.invoke();
  LOGI(TAG, "[predictStyle] Elapsed: %.3fs", stopwatch.getMs() / 1000.0f);

  auto outputTensor = interpreter.getOutputTensor(0);
  vector<float> output(100);
  assert(TfLiteTensorByteSize(outputTensor) == output.size() * sizeof(float));
  TfLiteTensorCopyToBuffer(outputTensor, output.data(),
                           output.size() * sizeof(float));
  return output;
}

vector<float>
ArbitraryStyleTransfer::blendBottleneck(const vector<float> &style,
                                        const vector<float> &image,
                                        const float styleWeight) {
  assert(style.size() == 100);
  assert(image.size() == 100);
  vector<float> product(100);
  for (int i = 0; i < 100; ++i) {
    product[i] = styleWeight * style[i] + (1 - styleWeight) * image[i];
  }
  return product;
}

} // namespace
