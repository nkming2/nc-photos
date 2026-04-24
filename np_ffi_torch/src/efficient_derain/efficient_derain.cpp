#include <cstddef>
#include <exception>
#include <executorch/runtime/core/exec_aten/exec_aten.h>
#include <vector>

#include "../log.h"
#include "../model_loader.h"
#include "../np_ffi_torch.h"
#include "../pad_image.h"
#include "../stopwatch.h"
#include "../util.h"

using namespace executorch::aten;
using namespace executorch::runtime;
using namespace np_torch;
using namespace std;

#define TAG "EfficientDerain"

namespace {

class EfficientDerain {
public:
  TorchRgb8Image *infer(const TorchRgb8Image *input, const char *modelPath);
};

} // namespace

TorchRgb8Image *inferEfficientDerain(const TorchRgb8Image *input,
                                     const char *modelPath) {
  return EfficientDerain().infer(input, modelPath);
}

namespace {

TorchRgb8Image *EfficientDerain::infer(const TorchRgb8Image *input,
                                       const char *modelPath) {
  auto loader = ModelLoader(modelPath);
  if (!loader.ok()) {
    LOGE(TAG, "[infer] Failed to load model");
    return nullptr;
  }

  const TorchRgb8Image *padded = nullptr;
  TorchRgb8Image *result = nullptr;
  try {
    // pad input to be divisible by 4
    const unsigned padX = (4 - input->width % 4) % 4;
    const unsigned padY = (4 - input->height % 4) % 4;
    padded = input;
    if (padX > 0 || padY > 0) {
      padded = padImage(input, padX, padY);
      LOGI(TAG, "[infer] Image padded as %d*%d", padded->width, padded->height);
    }

    auto inputData =
        rgb8To3hwFloat(padded->pixel, padded->width, padded->height);
    SizesType sizes[] = {1, 3, static_cast<int>(padded->height),
                         static_cast<int>(padded->width)};
    if (padded != input) {
      torchRgb8ImageFree(const_cast<TorchRgb8Image *>(padded));
      padded = nullptr;
    }
    DimOrderType dimOrder[] = {0, 1, 2, 3};
    TensorImpl tensorImpl(ScalarType::Float, 4, sizes, inputData.data(),
                          dimOrder);
    Tensor t(&tensorImpl);

    const auto setInputError = loader.method()->set_input(t, 0);
    if (setInputError != Error::Ok) {
      LOGE(TAG, "[infer] Failed to set input");
      return nullptr;
    }
    LOGI(TAG, "[infer] Run execute()");
    Stopwatch s;
    const auto executeError = loader.method()->execute();
    if (executeError != Error::Ok) {
      LOGE(TAG, "[infer] Failed to execute method");
      return nullptr;
    }
    LOGI(TAG, "[infer] Done, execute() took %ldms", s.getMs());
    inputData.clear();

    auto output = loader.method()->get_output(0);
    if (!output.isTensor()) {
      LOGE(TAG, "[infer] Output is not a tensor");
      return nullptr;
    }
    auto outputData =
        from3hwFloatToRgb8((const float *)output.toTensor().const_data_ptr(),
                           input->width + padX, input->height + padY);
    try {
      result =
          makeRgb8Image(outputData, input->width + padX, input->height + padY);
    } catch (exception &e) {
      LOGE(TAG, "[infer] Failed to create output image: %s", e.what());
      return nullptr;
    }
    if (padX > 0 || padY > 0) {
      auto unpadded = unpadImage(result, padX, padY);
      torchRgb8ImageFree(result);
      result = nullptr;
      return unpadded;
    } else {
      return result;
    }
  } catch (...) {
    if (padded && padded != input) {
      torchRgb8ImageFree(const_cast<TorchRgb8Image *>(padded));
    }
    if (result) {
      torchRgb8ImageFree(result);
    }
    throw;
  }
}

} // namespace
