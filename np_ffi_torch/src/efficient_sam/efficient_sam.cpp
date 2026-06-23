#include <algorithm>
#include <executorch/runtime/core/exec_aten/exec_aten.h>
#include <executorch/runtime/core/result.h>
#include <numeric>
#include <vector>

#include "../log.h"
#include "../model_loader.h"
#include "../np_ffi_torch.h"
#include "../stopwatch.h"
#include "../util.h"
#include "efficient_sam.h"

using namespace executorch::aten;
using namespace executorch::runtime;
using namespace np_torch;
using namespace std;

#define TAG "EfficientSam"

namespace np_torch {

EfficientSam::Result EfficientSam::infer(const TorchRgb8Image *input,
                                         const TorchPoint *points,
                                         const int *pointLabels,
                                         const char *modelPath) {
  auto loader = ModelLoader(modelPath);
  if (!loader.ok()) {
    LOGE(TAG, "[infer] Failed to load model");
    return {};
  }

  auto imageData = rgb8To3hwFloat(input->pixel, input->width, input->height);
  SizesType imageSize[] = {1, 3, static_cast<int>(input->height),
                           static_cast<int>(input->width)};
  DimOrderType imageDimOrder[] = {0, 1, 2, 3};
  TensorImpl imageTensorImpl(ScalarType::Float, 4, imageSize, imageData.data(),
                             imageDimOrder);
  Tensor imageTensor(&imageTensorImpl);

  array<float, 6 * 2> pointData;
  for (int i = 0; i < 6; ++i) {
    pointData[i * 2] = points[i].x;
    pointData[i * 2 + 1] = points[i].y;
  }
  SizesType pointSize[] = {1, 1, 6, 2};
  DimOrderType pointDimOrder[] = {0, 1, 2, 3};
  TensorImpl pointTensorImpl(ScalarType::Float, 4, pointSize, pointData.data(),
                             pointDimOrder);
  Tensor pointTensor(&pointTensorImpl);

  array<float, 6> labelData;
  for (int i = 0; i < 6; ++i) {
    labelData[i] = pointLabels[i];
  }
  SizesType labelSize[] = {1, 1, 6};
  DimOrderType labelDimOrder[] = {0, 1, 2};
  TensorImpl labelTensorImpl(ScalarType::Float, 3, labelSize, labelData.data(),
                             labelDimOrder);
  Tensor labelTensor(&labelTensorImpl);

  auto set_input_error = loader.method()->set_input(imageTensor, 0);
  if (set_input_error != Error::Ok) {
    LOGE(TAG, "[infer] Failed to set image input");
    return {};
  }
  set_input_error = loader.method()->set_input(pointTensor, 1);
  if (set_input_error != Error::Ok) {
    LOGE(TAG, "[infer] Failed to set point input");
    return {};
  }
  set_input_error = loader.method()->set_input(labelTensor, 2);
  if (set_input_error != Error::Ok) {
    LOGE(TAG, "[infer] Failed to set label input");
    return {};
  }
  LOGI(TAG, "[infer] Run execute()");
  Stopwatch s;
  const auto execute_error = loader.method()->execute();
  if (execute_error != Error::Ok) {
    LOGE(TAG, "[infer] Failed to execute method");
    return {};
  }
  LOGI(TAG, "[infer] Done, execute() took %ld", s.getMs());
  imageData.clear();

  auto logits = loader.method()->get_output(0);
  if (!logits.isTensor()) {
    LOGE(TAG, "[infer] Output is not a tensor");
    return {};
  }
  // [1, 1, 3(mask count), 256, 256]
  auto logitsTensor = logits.toTensor();
  auto logitsData = (const float *)logitsTensor.const_data_ptr();

  auto iou = loader.method()->get_output(1);
  if (!iou.isTensor()) {
    LOGE(TAG, "[infer] Output is not a tensor");
    return {};
  }
  // [1, 1, 3]
  auto iouTensor = iou.toTensor();
  auto iouData = (const float *)iouTensor.const_data_ptr();

  static constexpr int maskCount = 3;
  static constexpr size_t maskSize = 256 * 256;

  // take the mask with highest IoU score (ported from python example)
  vector<int> sortedIds(maskCount);
  iota(sortedIds.begin(), sortedIds.end(), 0);
  sort(sortedIds.begin(), sortedIds.end(),
       [&](int a, int b) { return iouData[a] > iouData[b]; });
  const int bestMask = sortedIds[0];
  const float *bestLogits = logitsData + bestMask * maskSize;
  vector<char> mask(maskSize);
  for (size_t i = 0; i < maskSize; ++i) {
    mask[i] = bestLogits[i] >= .0f;
  }

  return Result{
      .mask = std::move(mask),
  };
}

} // namespace np_torch
