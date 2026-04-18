#include <cstring>
#include <exception>
#include <executorch/runtime/core/exec_aten/exec_aten.h>
#include <vector>

#include "../log.h"
#include "../model_loader.h"
#include "../np_ffi_torch.h"
#include "../stopwatch.h"
#include "../util.h"

using namespace executorch::aten;
using namespace executorch::runtime;
using namespace np_torch;
using namespace std;

#define TAG "RealEsrgan"

namespace {

class RealEsrgan {
public:
  bool init(const char *modelPath);

  TorchRgb8Image *infer(const TorchRgb8Image *input);

private:
  std::unique_ptr<ModelLoader> loader_;
};

constexpr size_t kTileSize = 128;
// padding is needed to reduce border artifacts between two tiles
constexpr size_t kPadding = 16;
constexpr size_t kScale = 4;

} // namespace

TorchRgb8Image *inferRealEsrgan(const TorchRgb8Image *input,
                                const char *modelPath) {
  auto model = RealEsrgan();
  if (!model.init(modelPath)) {
    return nullptr;
  }
  // ESRGAN is extremely memory intensive, we need to split the image and stich
  // back together after inference to avoid OOM
  const auto tileXCount = input->width <= kTileSize
                              ? 1u
                              : (unsigned)ceil((input->width - kTileSize) /
                                               (double)(kTileSize - kPadding)) +
                                    1;
  const auto tileYCount = input->height <= kTileSize
                              ? 1u
                              : (unsigned)ceil((input->height - kTileSize) /
                                               (double)(kTileSize - kPadding)) +
                                    1;
  LOGI(TAG, "[inferRealEsrgan] Split into %u*%u tiles", tileXCount, tileYCount);
  const auto dstW = input->width * kScale;
  const auto dstH = input->height * kScale;
  vector<uint8_t> pixel(dstW * dstH * 3);
  for (auto y = 0u; y < tileYCount; ++y) {
    const auto tileH =
        min(kTileSize, input->height - y * (kTileSize - kPadding));
    const auto srcTop = y * (kTileSize - kPadding);
    for (auto x = 0u; x < tileXCount; ++x) {
      const auto tileW =
          min(kTileSize, input->width - x * (kTileSize - kPadding));
      const auto srcLeft = x * (kTileSize - kPadding);
      const auto tile = subImage(input, srcLeft, srcTop, tileW, tileH);
      try {
        LOGI(TAG,
             "[inferRealEsrgan] Processing tile %u-%u (%lu, %lu) (%lu*%lu)", x,
             y, srcLeft, srcTop, tileW, tileH);
        const auto processed = model.infer(tile);
        try {
          const auto dstTop = y * (kTileSize - kPadding) * kScale;
          const auto dstLeft = x * (kTileSize - kPadding) * kScale;
#pragma omp parallel for
          for (size_t ty = 0; ty < tileH * kScale; ++ty) {
            // take half the padding from each side
            if (y != 0 && ty < kPadding * kScale / 2) {
              continue;
            }
            const auto offsetX = (x == 0) ? 0 : kPadding / 2;
            memcpy(pixel.data() +
                       ((dstTop + ty) * dstW + dstLeft + (offsetX * kScale)) *
                           3,
                   processed->pixel +
                       (ty * processed->width + (offsetX * kScale)) * 3,
                   (processed->width - (offsetX * kScale)) * 3);
          }
        } catch (...) {
          torchRgb8ImageFree(processed);
          throw;
        }
      } catch (...) {
        torchRgb8ImageFree(tile);
        throw;
      }
    }
  }
  return makeRgb8Image(pixel, input->width * 4, input->height * 4);
}

namespace {

bool RealEsrgan::init(const char *modelPath) {
  loader_ = make_unique<ModelLoader>(modelPath);
  if (!loader_->ok()) {
    LOGE(TAG, "[init] Failed to load model");
    return false;
  }
  return true;
}

TorchRgb8Image *RealEsrgan::infer(const TorchRgb8Image *input) {
  assert(loader_ && loader_->ok());
  auto inputData = rgb8To3hwFloat(input->pixel, input->width, input->height);
  SizesType sizes[] = {1, 3, static_cast<int>(input->height),
                       static_cast<int>(input->width)};
  DimOrderType dimOrder[] = {0, 1, 2, 3};
  TensorImpl tensorImpl(ScalarType::Float, 4, sizes, inputData.data(),
                        dimOrder);
  Tensor t(&tensorImpl);

  const auto setInputError = loader_->method()->set_input(t, 0);
  if (setInputError != Error::Ok) {
    LOGE(TAG, "[infer] Failed to set input");
    return nullptr;
  }
  LOGI(TAG, "[infer] Run execute()");
  Stopwatch s;
  const auto executeError = loader_->method()->execute();
  if (executeError != Error::Ok) {
    LOGE(TAG, "[infer] Failed to execute method");
    return nullptr;
  }
  LOGI(TAG, "[infer] Done, execute() took %ldms", s.getMs());
  inputData.clear();

  auto output = loader_->method()->get_output(0);
  if (!output.isTensor()) {
    LOGE(TAG, "[infer] Output is not a tensor");
    return nullptr;
  }
  auto outputData =
      from3hwFloatToRgb8((const float *)output.toTensor().const_data_ptr(),
                         input->width * 4, input->height * 4);
  try {
    return makeRgb8Image(outputData, input->width * 4, input->height * 4);
  } catch (exception &e) {
    LOGE(TAG, "[infer] Failed to create output image: %s", e.what());
    return nullptr;
  }
}

} // namespace
