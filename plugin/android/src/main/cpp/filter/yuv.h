#pragma once

#include <array>
#include <cstdint>

namespace plugin {
namespace filter {

/**
 * Map a RGB color to full range YCbCr
 *
 * @param rgb8
 * @return Returned values are in the range of 0 to 1
 */
std::array<float, 3> rgb8ToYuv(const uint8_t *rgb8);

/**
 * Map a full range YCbCr color to RGB
 *
 * @param yuv
 * @return
 */
std::array<uint8_t, 3> yuvToRgb8(const float *yuv);

} // namespace filter
} // namespace plugin
