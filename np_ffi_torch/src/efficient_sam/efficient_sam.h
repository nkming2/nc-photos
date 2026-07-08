#pragma once

#include <vector>

#include "../np_ffi_torch.h"

namespace np_torch {

class EfficientSam {
public:
  struct Result {
    operator bool() const { return !mask.empty(); }

    // vector<bool>
    std::vector<char> mask;
    static constexpr size_t width = 256;
    static constexpr size_t height = 256;
  };

  // points and pointLabels must have size == 6
  Result infer(const TorchRgb8Image *input, const TorchPoint *points,
               const int *pointLabels, const char *modelPath);
};

} // namespace np_torch
