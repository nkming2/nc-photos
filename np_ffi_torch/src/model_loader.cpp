#include <executorch/extension/data_loader/file_data_loader.h>
#include <executorch/runtime/core/exec_aten/exec_aten.h>
#include <executorch/runtime/core/result.h>
#include <executorch/runtime/executor/memory_manager.h>
#include <executorch/runtime/executor/program.h>
#include <string>

#include "log.h"
#include "memory_context.h"
#include "model_loader.h"

using namespace executorch::runtime;
using executorch::extension::FileDataLoader;
using namespace std;

namespace np_torch {

ModelLoader::ModelLoader(const std::string &modelPath,
                         const std::string &methodName) {
  loaderPtr_ = make_unique<Result<FileDataLoader>>(
      FileDataLoader::from(modelPath.c_str()));
  if (!loader().ok()) {
    LOGE("ModelLoader", "Failed to load model");
    return;
  }
  programPtr_ = make_unique<Result<Program>>(Program::load(&loader().get()));
  if (!program().ok()) {
    LOGE("ModelLoader", "Failed to load program");
    return;
  }
  memoryPtr_ = make_unique<MemoryContext>(&program().get());
  if (!memory().get()) {
    LOGE("ModelLoader", "Failed to create MemoryContext");
    return;
  }
  methodPtr_ = make_unique<Result<Method>>(
      program()->load_method(methodName.c_str(), memory().get()));
  if (!method().ok()) {
    LOGE("ModelLoader", "Failed to load method");
    return;
  }
}

bool ModelLoader::ok() const {
  return loaderPtr_ && programPtr_ && memoryPtr_ && methodPtr_ &&
         loader().ok() && program().ok() && memory().ok() && method().ok();
}

} // namespace np_torch
