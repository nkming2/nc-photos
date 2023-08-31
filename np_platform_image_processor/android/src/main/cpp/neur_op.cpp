#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>
#include <cassert>
#include <exception>
#include <jni.h>
#include <tensorflow/lite/c/c_api.h>

#include "exception.h"
#include "log.h"
#include "stopwatch.h"
#include "tflite_wrapper.h"
#include "util.h"

using namespace im_proc;
using namespace std;
using namespace tflite;

namespace {

constexpr const char *MODEL = "tf/neurop_fivek_lite.tflite";

class NeurOp {
public:
  explicit NeurOp(AAssetManager *const aam);

  std::vector<uint8_t> infer(const uint8_t *image, const size_t width,
                             const size_t height);

private:
  Model model;

  static constexpr const char *TAG = "NeurOp";
};

} // namespace

extern "C" JNIEXPORT jbyteArray JNICALL
Java_com_nkming_nc_1photos_np_1platform_1image_1processor_processor_NeurOp_inferNative(
    JNIEnv *env, jobject *thiz, jobject assetManager, jbyteArray image,
    jint width, jint height) {
  try {
    initOpenMp();
    auto aam = AAssetManager_fromJava(env, assetManager);
    NeurOp model(aam);
    RaiiContainer<jbyte> cImage(
        [&]() { return env->GetByteArrayElements(image, nullptr); },
        [&](jbyte *obj) {
          env->ReleaseByteArrayElements(image, obj, JNI_ABORT);
        });
    const auto result =
        model.infer(reinterpret_cast<uint8_t *>(cImage.get()), width, height);
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

NeurOp::NeurOp(AAssetManager *const aam) : model(Asset(aam, MODEL)) {}

vector<uint8_t> NeurOp::infer(const uint8_t *image, const size_t width,
                              const size_t height) {
  InterpreterOptions options;
  options.setNumThreads(getNumberOfProcessors());
  Interpreter interpreter(model, options);
  const int dims[] = {1, static_cast<int>(height), static_cast<int>(width), 3};
  interpreter.resizeInputTensor(0, dims, 4);
  interpreter.allocateTensors();

  LOGI(TAG, "[infer] Convert bitmap to input");
  auto input = rgb8ToRgbFloat(image, width * height * 3, true);
  auto inputTensor = interpreter.getInputTensor(0);
  assert(TfLiteTensorByteSize(inputTensor) == input.size() * sizeof(float));
  TfLiteTensorCopyFromBuffer(inputTensor, input.data(),
                             input.size() * sizeof(float));
  input.clear();

  LOGI(TAG, "[infer] Inferring");
  Stopwatch stopwatch;
  interpreter.invoke();
  LOGI(TAG, "[infer] Elapsed: %.3fs", stopwatch.getMs() / 1000.0f);

  auto outputTensor = interpreter.getOutputTensor(0);
  vector<float> output(width * height * 3);
  assert(TfLiteTensorByteSize(outputTensor) == output.size() * sizeof(float));
  TfLiteTensorCopyToBuffer(outputTensor, output.data(),
                           output.size() * sizeof(float));
  return rgbFloatToRgb8(output.data(), output.size(), true);
}

} // namespace
