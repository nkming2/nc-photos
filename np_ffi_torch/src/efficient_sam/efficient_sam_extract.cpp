#include <base_resample.h>
#include <cstddef>
#include <cstdint>
#include <vector>

#include "../log.h"
#include "../np_ffi_torch.h"
#include "../util.h"
#include "efficient_sam.h"

using namespace np_torch;
using namespace std;

#define TAG "EfficientSamExtract"

namespace {

class EfficientSamExtract {
public:
  TorchRgba8Image *infer(const TorchRgb8Image *input, const TorchPoint *points,
                         const int *pointLabels, const char *modelPath);
};

} // namespace

TorchRgba8Image *inferEfficientSamExtract(const TorchRgb8Image *input,
                                          const TorchPoint *points,
                                          const int *pointLabels,
                                          const char *modelPath) {
  return EfficientSamExtract().infer(input, points, pointLabels, modelPath);
}

namespace {

TorchRgba8Image *EfficientSamExtract::infer(const TorchRgb8Image *input,
                                            const TorchPoint *points,
                                            const int *pointLabels,
                                            const char *modelPath) {
  EfficientSam model;
  const auto result = model.infer(input, points, pointLabels, modelPath);
  if (!result) {
    return nullptr;
  }
  vector<uint8_t> mask(result.width * result.height);
  for (size_t i = 0; i < result.width * result.height; ++i) {
    mask[i] = result.mask[i] ? 0xFF : 0;
  }
  vector<uint8_t> scaledMask(input->width * input->height);
  const auto scaleResult = base::ResampleImage<1>(
      mask.data(), result.width, result.height, scaledMask.data(), input->width,
      input->height, base::KernelTypeBilinear);
  if (!scaleResult) {
    LOGE(TAG, "[infer] Failed while ResampleImage");
    return nullptr;
  }

  vector<uint8_t> pixel(input->width * input->height * 4);
  for (size_t i = 0; i < input->width * input->height; ++i) {
    if (scaledMask[i] == 0) {
      pixel[i * 4] = 0;
      pixel[i * 4 + 1] = 0;
      pixel[i * 4 + 2] = 0;
      pixel[i * 4 + 3] = 0;
    } else {
      pixel[i * 4] = input->pixel[i * 3];
      pixel[i * 4 + 1] = input->pixel[i * 3 + 1];
      pixel[i * 4 + 2] = input->pixel[i * 3 + 2];
      pixel[i * 4 + 3] = scaledMask[i];
    }
  }
  return makeRgba8Image(pixel, input->width, input->height);
}

} // namespace
