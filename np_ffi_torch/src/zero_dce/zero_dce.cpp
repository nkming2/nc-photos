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

#define TAG "ZeroDce"

namespace {

class ZeroDce {
public:
  TorchRgb8Image *infer(const TorchRgb8Image *input, const char *modelPath);
};

} // namespace

TorchRgb8Image *inferZeroDce(const TorchRgb8Image *input,
                             const char *modelPath) {
  return ZeroDce().infer(input, modelPath);
}

namespace {

TorchRgb8Image *ZeroDce::infer(const TorchRgb8Image *input,
                               const char *modelPath) {
  auto loader = ModelLoader(modelPath);
  if (!loader.ok()) {
    LOGE(TAG, "[infer] Failed to load model");
    return nullptr;
  }

  auto input_data = rgb8To3hwFloat(input->pixel, input->width, input->height);
  SizesType sizes[] = {1, 3, static_cast<int>(input->height),
                       static_cast<int>(input->width)};
  DimOrderType dim_order[] = {0, 1, 2, 3};
  TensorImpl tensor_impl(ScalarType::Float, 4, sizes, input_data.data(),
                         dim_order);
  Tensor t(&tensor_impl);

  const auto set_input_error = loader.method()->set_input(t, 0);
  if (set_input_error != Error::Ok) {
    LOGE(TAG, "[infer] Failed to set input");
    return nullptr;
  }
  LOGI(TAG, "[infer] Run execute()");
  Stopwatch s;
  const auto execute_error = loader.method()->execute();
  if (execute_error != Error::Ok) {
    LOGE(TAG, "[infer] Failed to execute method");
    return nullptr;
  }
  LOGI(TAG, "[infer] Done, execute() took %ld", s.getMs());
  input_data.clear();

  auto output = loader.method()->get_output(1);
  if (!output.isTensor()) {
    LOGE(TAG, "[infer] Output is not a tensor");
    return nullptr;
  }
  auto output_data =
      from3hwFloatToRgb8((const float *)output.toTensor().const_data_ptr(),
                         input->width, input->height);
  try {
    return makeRgb8Image(output_data, input->width, input->height);
  } catch (exception &e) {
    LOGE(TAG, "[infer] Failed to create output image: %s", e.what());
    return nullptr;
  }
}

} // namespace
