#include "exception.h"
#include "image_splitter.h"
#include "log.h"
#include "stopwatch.h"
#include "tflite_wrapper.h"
#include "util.h"
#include <algorithm>
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>
#include <cassert>
#include <cstdint>
#include <cstring>
#include <exception>
#include <jni.h>
#include <omp.h>
#include <tensorflow/lite/c/c_api.h>
#include <vector>

using namespace plugin;
using namespace std;
using namespace tflite;

namespace {

constexpr const char *MODEL = "tf/esrgan-tf2_1-dr.tflite";
constexpr const size_t TILE_SIZE = 118;
constexpr const size_t TILE_PADDING = 10;

class Esrgan {
public:
  explicit Esrgan(AAssetManager *const aam);

  std::vector<uint8_t> infer(const uint8_t *image, const size_t width,
                             const size_t height);

private:
  std::vector<uint8_t> inferSingle(const uint8_t *image, const size_t width,
                                   const size_t height);
  std::vector<uint8_t>
  joinTiles(const std::vector<std::vector<ImageTile>> &tiles);

  Model model;

  static constexpr const char *TAG = "Esrgan";
};

} // namespace

extern "C" JNIEXPORT jbyteArray JNICALL
Java_com_nkming_nc_1photos_plugin_image_1processor_Esrgan_inferNative(
    JNIEnv *env, jobject *thiz, jobject assetManager, jbyteArray image,
    jint width, jint height) {
  try {
    initOpenMp();
    auto aam = AAssetManager_fromJava(env, assetManager);
    Esrgan model(aam);
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

Esrgan::Esrgan(AAssetManager *const aam) : model(Asset(aam, MODEL)) {}

vector<uint8_t> Esrgan::infer(const uint8_t *image, const size_t width,
                              const size_t height) {
  // doing ESRGAN in one pass requires loads of memory, so we split the image
  // into smaller tiles
  const ImageSplitter splitter(TILE_SIZE, TILE_SIZE, TILE_PADDING);
  auto tiles = splitter(image, width, height, 3);
  const size_t tileCount = tiles.size() * (tiles.empty() ? 0 : tiles[0].size());
  auto i = 0;
  for (auto &row : tiles) {
    for (auto &t : row) {
      LOGI(TAG, "[infer] Tile#%d/%zu", i++, tileCount);
      auto result = inferSingle(t.data().data(), t.width(), t.height());
      t = ImageTile(move(result), t.width() * 4, t.height() * 4, 3);
    }
  }

  // when joining tiles, we use half of paddings from next tile to cover the
  // prev tile
  vector<uint8_t> output(width * 4 * height * 4 * 3);
#pragma omp parallel for
  for (size_t ty = 0; ty < tiles.size(); ++ty) {
    const auto thisTilePaddingH = ty == 0 ? 0 : TILE_PADDING * 4;
    const auto thisTileBegY = thisTilePaddingH / 2;
    for (size_t tx = 0; tx < tiles[ty].size(); ++tx) {
      const auto thisTilePaddingW = tx == 0 ? 0 : TILE_PADDING * 4;
      const auto thisTileBegX = thisTilePaddingW / 2;
      const ImageTile &tile = tiles[ty][tx];
      const auto thisTileEndY =
          tile.height() - (ty == tiles.size() - 1 ? 0 : TILE_PADDING * 4 / 2);
      const auto thisTileEndX =
          tile.width() -
          (tx == tiles[ty].size() - 1 ? 0 : TILE_PADDING * 4 / 2);
      for (size_t dy = thisTileBegY; dy < thisTileEndY; ++dy) {
        const auto srcOffset = (dy * tile.width() + thisTileBegX) * 3;
        const auto dstOffset =
            ((ty * TILE_SIZE * 4 - thisTilePaddingH + dy) * width * 4 +
             tx * TILE_SIZE * 4 - thisTilePaddingW + thisTileBegX) *
            3;
        memcpy(output.data() + dstOffset, tile.data().data() + srcOffset,
               (thisTileEndX - thisTileBegX) * 3);
      }
    }
  }
  return output;
}

vector<uint8_t> Esrgan::inferSingle(const uint8_t *image, const size_t width,
                                    const size_t height) {
  InterpreterOptions options;
  options.setNumThreads(getNumberOfProcessors());
  Interpreter interpreter(model, options);
  const int dims[] = {1, static_cast<int>(height), static_cast<int>(width), 3};
  interpreter.resizeInputTensor(0, dims, 4);
  interpreter.allocateTensors();

  LOGI(TAG, "[inferSingle] Convert bitmap to input");
  const auto input = rgb8ToRgbFloat(image, width * height * 3, false);
  auto inputTensor = interpreter.getInputTensor(0);
  assert(TfLiteTensorByteSize(inputTensor) == input.size() * sizeof(float));
  TfLiteTensorCopyFromBuffer(inputTensor, input.data(),
                             input.size() * sizeof(float));

  LOGI(TAG, "[inferSingle] Inferring");
  Stopwatch stopwatch;
  interpreter.invoke();
  LOGI(TAG, "[inferSingle] Elapsed: %.3fs", stopwatch.getMs() / 1000.0f);

  auto outputTensor = interpreter.getOutputTensor(0);
  vector<float> output(width * 4 * height * 4 * 3);
  assert(TfLiteTensorByteSize(outputTensor) == output.size() * sizeof(float));
  TfLiteTensorCopyToBuffer(outputTensor, output.data(),
                           output.size() * sizeof(float));
  return rgbFloatToRgb8(output.data(), output.size(), false);
}

} // namespace
