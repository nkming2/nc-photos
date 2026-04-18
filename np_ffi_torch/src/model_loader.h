#pragma once

#include <executorch/extension/data_loader/file_data_loader.h>
#include <executorch/runtime/core/exec_aten/exec_aten.h>
#include <executorch/runtime/core/result.h>
#include <executorch/runtime/executor/memory_manager.h>
#include <executorch/runtime/executor/program.h>
#include <memory>
#include <string>

#include "memory_context.h"

namespace np_torch {

class ModelLoader {
public:
  ModelLoader(const std::string &modelPath,
              const std::string &methodName = "forward");

  bool ok() const;

  executorch::runtime::Result<executorch::runtime::Method> &method() {
    return *methodPtr_;
  }

  const executorch::runtime::Result<executorch::runtime::Method> &
  method() const {
    return *methodPtr_;
  }

private:
  executorch::runtime::Result<executorch::extension::FileDataLoader> &loader() {
    return *loaderPtr_;
  }

  const executorch::runtime::Result<executorch::extension::FileDataLoader> &
  loader() const {
    return *loaderPtr_;
  }

  executorch::runtime::Result<executorch::runtime::Program> &program() {
    return *programPtr_;
  }

  const executorch::runtime::Result<executorch::runtime::Program> &
  program() const {
    return *programPtr_;
  }

  MemoryContext &memory() { return *memoryPtr_; }

  const MemoryContext &memory() const { return *memoryPtr_; }

  std::unique_ptr<
      executorch::runtime::Result<executorch::extension::FileDataLoader>>
      loaderPtr_;
  std::unique_ptr<executorch::runtime::Result<executorch::runtime::Program>>
      programPtr_;
  std::unique_ptr<MemoryContext> memoryPtr_;
  std::unique_ptr<executorch::runtime::Result<executorch::runtime::Method>>
      methodPtr_;
};

} // namespace np_torch
