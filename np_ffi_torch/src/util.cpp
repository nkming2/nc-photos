#include <algorithm>
#include <cassert>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <omp.h>
#include <vector>

#include "log.h"
#include "np_ffi_torch.h"
#include "util.h"

using namespace std;

namespace np_torch {

void initOpenMp() {
  const auto count = omp_get_num_procs();
  LOGI("OpenMp", "Number of threads: %d", count);
  omp_set_num_threads(count);
}

vector<float> uint8ToFloat(const uint8_t *src, const size_t size,
                           const bool shouldNormalize) {
  vector<float> result(size);
#pragma omp parallel for
  for (size_t i = 0; i < size; ++i) {
    if (shouldNormalize) {
      result[i] = src[i] / 255.0f;
    } else {
      result[i] = src[i];
    }
  }
  return result;
}

vector<float> uint8ToFloatStd(const uint8_t *src, const size_t size,
                              const vector<float> &mean,
                              const vector<float> &std) {
  assert(mean.size() == std.size());
  const auto channelCount = min(mean.size(), std.size());
  vector<float> result(size);
#pragma omp parallel for
  for (size_t i = 0; i < size; ++i) {
    const float normalized = src[i] / 255.0f;
    if (channelCount == 0) {
      result[i] = normalized;
      continue;
    }
    const size_t ch = i % channelCount;
    const float s = std[ch] == 0.f ? 1.f : std[ch];
    result[i] = (normalized - mean[ch]) / s;
  }
  return result;
}

vector<float> rgb8To3hwFloatStd(const uint8_t *src, const size_t width,
                                const size_t height, const vector<float> &mean,
                                const vector<float> &std) {
  assert(mean.size() == std.size());
  assert(mean.size() == 3 || mean.empty());
  const size_t area = width * height;
  vector<float> result(area * 3);
#pragma omp parallel for
  for (size_t i = 0; i < area; ++i) {
    const auto r = src[i * 3] / 255.f;
    const auto g = src[i * 3 + 1] / 255.f;
    const auto b = src[i * 3 + 2] / 255.f;
    if (mean.empty()) {
      result[i] = r;
      result[area + i] = g;
      result[area * 2 + i] = b;
    } else {
      result[i] = (r - mean[0]) / (std[0] == 0.f ? 1.f : std[0]);
      result[area + i] = (g - mean[1]) / (std[1] == 0.f ? 1.f : std[1]);
      result[area * 2 + i] = (b - mean[2]) / (std[2] == 0.f ? 1.f : std[2]);
    }
  }
  return result;
}

vector<uint8_t> floatToUint8(const float *src, const size_t size,
                             const bool isNormalized) {
  vector<uint8_t> result(size);
#pragma omp parallel for
  for (size_t i = 0; i < size; ++i) {
    if (isNormalized) {
      result[i] = clamp(src[i], 0.f, 1.f) * 255.f;
    } else {
      result[i] = (uint8_t)clamp(src[i], 0.f, 255.f);
    }
  }
  return result;
}

vector<uint8_t> from3hwFloatToRgb8(const float *src, const size_t width,
                                   const size_t height) {
  const size_t area = width * height;
  vector<uint8_t> result(area * 3);
#pragma omp parallel for
  for (size_t i = 0; i < area; ++i) {
    result[i * 3] = clamp(src[i], 0.f, 1.f) * 255.f;
    result[i * 3 + 1] = clamp(src[area + i], 0.f, 1.f) * 255.f;
    result[i * 3 + 2] = clamp(src[area * 2 + i], 0.f, 1.f) * 255.f;
  }
  return result;
}

TorchRgb8Image *makeRgb8Image(const vector<uint8_t> &pixel,
                              const unsigned width, const unsigned height) {
  auto c_pixel = copyVectorToCArray(pixel);
  try {
    TorchRgb8Image *image = (TorchRgb8Image *)malloc(sizeof(TorchRgb8Image));
    try {
      image->width = width;
      image->height = height;
      image->pixel = c_pixel;
      return image;
    } catch (...) {
      free(image);
      throw;
    }
  } catch (...) {
    free(c_pixel);
    throw;
  }
}

TorchRgba8Image *makeRgba8Image(const vector<uint8_t> &pixel,
                                const unsigned width, const unsigned height) {
  auto c_pixel = copyVectorToCArray(pixel);
  try {
    TorchRgba8Image *image = (TorchRgba8Image *)malloc(sizeof(TorchRgba8Image));
    try {
      image->width = width;
      image->height = height;
      image->pixel = c_pixel;
      return image;
    } catch (...) {
      free(image);
      throw;
    }
  } catch (...) {
    free(c_pixel);
    throw;
  }
}

TorchRgb8Image *subImage(const TorchRgb8Image *srcImage, const size_t left,
                         const size_t top, const size_t width,
                         const size_t height) {
  assert(left < srcImage->width);
  assert(top < srcImage->height);
  const auto w = min(width, srcImage->width - left);
  const auto h = min(height, srcImage->height - top);
  vector<uint8_t> pixel(w * h * 3);
#pragma omp parallel for
  for (size_t y = 0; y < h; ++y) {
    memcpy(pixel.data() + y * w * 3,
           srcImage->pixel + (top + y) * srcImage->width * 3 + left * 3, w * 3);
  }
  return makeRgb8Image(pixel, w, h);
}

} // namespace np_torch
