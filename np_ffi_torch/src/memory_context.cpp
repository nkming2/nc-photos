#include <executorch/runtime/core/hierarchical_allocator.h>
#include <executorch/runtime/core/span.h>
#include <executorch/runtime/executor/memory_manager.h>
#include <executorch/runtime/executor/program.h>
#include <memory>
#include <vector>

#include "log.h"
#include "malloc_memory_allocator.h"
#include "memory_context.h"

using namespace std;
using namespace executorch::runtime;

namespace np_torch {

MemoryContext::MemoryContext(Program *program) : program_(program) {}

void MemoryContext::initMemoryManager() {
  // MethodMeta is a lightweight structure that lets us gather metadata
  // information about a specific method. In this case we are looking to get the
  // required size of the memory planned buffers for the method "forward".
  auto methodMeta = program_->method_meta("forward");
  if (!methodMeta.ok()) {
    LOGE("MemoryContext", "Failed to get method meta");
    return;
  }

  auto numMemoryPlannedBuffers = methodMeta->num_memory_planned_buffers();

  // It is possible to have multiple layers in our memory hierarchy; for
  // example,
  // SRAM and DRAM.
  for (size_t id = 0; id < numMemoryPlannedBuffers; ++id) {
    auto bufferSize =
        static_cast<size_t>(methodMeta->memory_planned_buffer_size(id).get());
    LOGI("MemoryContext", "Allocating %zuMB memory", bufferSize / 1024 / 1024);
    plannedBuffers_.push_back(make_unique<uint8_t[]>(bufferSize));
    plannedArenas_.push_back({plannedBuffers_.back().get(), bufferSize});
  }
  plannedMemory_ = make_unique<HierarchicalAllocator>(
      HierarchicalAllocator({plannedArenas_.data(), plannedArenas_.size()}));

  // Version of MemoryAllocator that uses malloc to handle allocations rather
  // then
  // a fixed buffer.
  methodAllocator_ = make_unique<MallocMemoryAllocator>();

  // Assemble all of the allocators into the MemoryManager that the Executor
  // will use.
  memoryManager_ =
      make_unique<MemoryManager>(methodAllocator_.get(), plannedMemory_.get());
}

} // namespace np_torch
