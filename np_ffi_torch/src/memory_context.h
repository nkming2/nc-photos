#pragma once

#include <cstdint>
#include <executorch/runtime/core/span.h>
#include <executorch/runtime/executor/memory_manager.h>
#include <executorch/runtime/executor/program.h>
#include <memory>
#include <vector>

namespace np_torch {

class MemoryContext {
public:
  explicit MemoryContext(executorch::runtime::Program *program);

  executorch::runtime::MemoryManager *get() {
    if (!memoryManager_) {
      initMemoryManager();
    }
    return memoryManager_.get();
  }

  bool ok() const { return memoryManager_.get(); }

private:
  void initMemoryManager();

  executorch::runtime::Program *const program_;
  std::vector<std::unique_ptr<uint8_t[]>> plannedBuffers_;
  std::vector<executorch::runtime::Span<uint8_t>> plannedArenas_;
  std::unique_ptr<executorch::runtime::MemoryAllocator> methodAllocator_;
  std::unique_ptr<executorch::runtime::HierarchicalAllocator> plannedMemory_;
  std::unique_ptr<executorch::runtime::MemoryManager> memoryManager_;
};

} // namespace np_torch
