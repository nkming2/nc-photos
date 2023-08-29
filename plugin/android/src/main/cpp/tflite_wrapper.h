#pragma once

#include <cstdint>
#include <tensorflow/lite/c/c_api.h>

#include "util.h"

namespace tflite {

class Model {
public:
  explicit Model(plugin::Asset &&asset);
  Model(Model &&rhs);
  ~Model();

  const TfLiteModel *get() const { return model; }
  const void *getBuffer() const;
  const size_t getSize() const;

private:
  plugin::Asset asset;
  TfLiteModel *model;
};

class InterpreterOptions {
public:
  InterpreterOptions();
  ~InterpreterOptions();

  const TfLiteInterpreterOptions *get() const { return options; }
  void setNumThreads(const int num_threads);
  void addDelegate(TfLiteDelegate *delegate);

private:
  TfLiteInterpreterOptions *options = nullptr;
};

class Interpreter {
public:
  explicit Interpreter(const Model &model);
  Interpreter(const Model &model, const InterpreterOptions &options);
  ~Interpreter();

  int32_t getInputTensorCount() const;
  TfLiteTensor *getInputTensor(const int32_t inputIndex);
  TfLiteStatus resizeInputTensor(const int32_t inputIndex, const int *inputDims,
                                 const int32_t inputDimsSize);
  TfLiteStatus allocateTensors();
  TfLiteStatus invoke();
  int32_t getOutputTensorCount() const;
  const TfLiteTensor *getOutputTensor(const int32_t outputIndex);

private:
  Interpreter(const Model &model, const InterpreterOptions *options);

  TfLiteInterpreter *interpreter = nullptr;
};

} // namespace tflite
