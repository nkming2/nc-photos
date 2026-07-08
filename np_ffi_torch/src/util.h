#pragma once

#include "np_ffi_torch.h"
#include <cstdint>
#include <cstdlib>
#include <vector>

namespace np_torch {

void initOpenMp();

std::vector<float> uint8ToFloat(const uint8_t *src, const size_t size,
                                const bool shouldNormalize = true);

std::vector<float> uint8ToFloatStd(const uint8_t *src, const size_t size,
                                   const std::vector<float> &mean,
                                   const std::vector<float> &std);

// Convert RGB8 image array to standardized [3, H, W] shaped float array
std::vector<float> rgb8To3hwFloatStd(const uint8_t *src, const size_t width,
                                     const size_t height,
                                     const std::vector<float> &mean,
                                     const std::vector<float> &std);

inline std::vector<float> rgb8To3hwFloat(const uint8_t *src, const size_t width,
                                         const size_t height) {
  return rgb8To3hwFloatStd(src, width, height, {}, {});
}

std::vector<uint8_t> floatToUint8(const float *src, const size_t size,
                                  const bool isNormalized = true);

std::vector<uint8_t> from3hwFloatToRgb8(const float *src, const size_t width,
                                        const size_t height);

template <typename T> T *copyVectorToCArray(const std::vector<T> &src);

TorchRgb8Image *makeRgb8Image(const std::vector<uint8_t> &pixel, unsigned width,
                              unsigned height);

TorchRgba8Image *makeRgba8Image(const std::vector<uint8_t> &pixel,
                                unsigned width, unsigned height);

TorchRgb8Image *subImage(const TorchRgb8Image *srcImage, const size_t left,
                         const size_t top, const size_t width,
                         const size_t height);

} // namespace np_torch

#include "util.hpp" // IWYU pragma: export
