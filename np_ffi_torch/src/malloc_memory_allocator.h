#pragma once

#include "log.h"
#include <executorch/runtime/core/memory_allocator.h>
#include <vector>

namespace np_torch {

/**
 * Dynamically allocates memory using malloc() and frees all pointers at
 * destruction time.
 *
 * For systems with malloc(), this can be easier than using a fixed-sized
 * MemoryAllocator.
 */
class MallocMemoryAllocator : public executorch::runtime::MemoryAllocator {
public:
  MallocMemoryAllocator() : MemoryAllocator(0, nullptr) {}

  ~MallocMemoryAllocator() override { reset(); }

  /**
   * Allocates 'size' bytes of memory, returning a pointer to the allocated
   * region, or nullptr upon failure. The size will be rounded up based on the
   * memory alignment size.
   */
  void *allocate(size_t size, size_t alignment = kDefaultAlignment) override {
    EXECUTORCH_TRACK_ALLOCATION(prof_id(), size);

    if (!isPowerOf2(alignment)) {
      LOGE("MallocMemoryAllocator", "Alignment %zu is not a power of 2",
           alignment);
      return nullptr;
    }

    // The minimum alignment that malloc() is guaranteed to provide.
    static constexpr size_t kMallocAlignment = alignof(std::max_align_t);
    if (alignment > kMallocAlignment) {
      // To get higher alignments, allocate extra and then align the returned
      // pointer. This will waste an extra `alignment` bytes every time, but
      // this is the only portable way to get aligned memory from the heap.
      size += alignment;
    }
    memPtrs_.emplace_back(std::malloc(size));
    return alignPointer(memPtrs_.back(), alignment);
  }

  // Free up each hosted memory pointer. The memory was created via malloc.
  void reset() override {
    for (auto memPtr : memPtrs_) {
      free(memPtr);
    }
    memPtrs_.clear();
  }

private:
  std::vector<void *> memPtrs_;
};

} // namespace np_torch
