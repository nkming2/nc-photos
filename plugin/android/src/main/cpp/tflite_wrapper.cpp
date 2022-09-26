#include "tflite_wrapper.h"
#include "util.h"
#include <exception>
#include <tensorflow/lite/c/c_api.h>
#include <tensorflow/lite/delegates/gpu/delegate.h>

using namespace plugin;
using namespace std;

namespace tflite {

Model::Model(Asset &&a) : asset(std::move(a)) {
  model = TfLiteModelCreate(asset.getBuffer(), asset.getSize());
  if (!model) {
    throw runtime_error("Error loading model file");
  }
}

Model::Model(Model &&rhs) : asset(std::move(rhs.asset)), model(rhs.model) {
  rhs.model = nullptr;
}

Model::~Model() {
  if (model) {
    TfLiteModelDelete(model);
    model = nullptr;
  }
}

InterpreterOptions::InterpreterOptions() {
  options = TfLiteInterpreterOptionsCreate();
  if (!options) {
    throw runtime_error("Error calling TfLiteInterpreterOptionsCreate");
  }
}

InterpreterOptions::~InterpreterOptions() {
  if (options) {
    TfLiteInterpreterOptionsDelete(options);
  }
}

void InterpreterOptions::setNumThreads(const int num_threads) {
  TfLiteInterpreterOptionsSetNumThreads(options, num_threads);
}

void InterpreterOptions::addDelegate(TfLiteDelegate *delegate) {
  TfLiteInterpreterOptionsAddDelegate(options, delegate);
}

Interpreter::Interpreter(const Model &model) : Interpreter(model, nullptr) {}

Interpreter::Interpreter(const Model &model, const InterpreterOptions &options)
    : Interpreter(model, &options) {}

Interpreter::Interpreter(const Model &model,
                         const InterpreterOptions *options) {
  interpreter =
      TfLiteInterpreterCreate(model.get(), options ? options->get() : nullptr);
  if (!interpreter) {
    throw runtime_error("Error creating interpreter");
  }
}

Interpreter::~Interpreter() {
  if (interpreter) {
    TfLiteInterpreterDelete(interpreter);
    interpreter = nullptr;
  }
}

int32_t Interpreter::getInputTensorCount() const {
  return TfLiteInterpreterGetInputTensorCount(interpreter);
}

TfLiteTensor *Interpreter::getInputTensor(const int32_t inputIndex) {
  return TfLiteInterpreterGetInputTensor(interpreter, inputIndex);
}

TfLiteStatus Interpreter::resizeInputTensor(const int32_t inputIndex,
                                            const int *inputDims,
                                            const int32_t inputDimsSize) {
  return TfLiteInterpreterResizeInputTensor(interpreter, inputIndex, inputDims,
                                            inputDimsSize);
}

TfLiteStatus Interpreter::allocateTensors() {
  return TfLiteInterpreterAllocateTensors(interpreter);
}

TfLiteStatus Interpreter::invoke() {
  return TfLiteInterpreterInvoke(interpreter);
}

int32_t Interpreter::getOutputTensorCount() const {
  return TfLiteInterpreterGetOutputTensorCount(interpreter);
}

const TfLiteTensor *Interpreter::getOutputTensor(const int32_t outputIndex) {
  return TfLiteInterpreterGetOutputTensor(interpreter, outputIndex);
}

AutoTfLiteDelegate::~AutoTfLiteDelegate() {
  if (inst) {
    TfLiteGpuDelegateV2Delete(inst);
  }
}

} // namespace tflite