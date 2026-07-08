#pragma once

#include <vector>

#include "util.h"

namespace np_torch {

template <typename T> T *copyVectorToCArray(const std::vector<T> &src) {
  if (src.empty()) {
    return nullptr;
  }
  T *result = (T *)malloc(src.size() * sizeof(T));
#pragma omp parallel for
  for (size_t i = 0; i < src.size(); ++i) {
    result[i] = src[i];
  }
  return result;
}

} // namespace np_torch
