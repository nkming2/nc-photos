#pragma once

#include <array>
#include <cstdint>

namespace plugin {
namespace filter {

std::array<float, 3> rgb8ToHsl(const uint8_t *rgb8);
std::array<float, 3> rgb8ToHsv(const uint8_t *rgb8);

std::array<uint8_t, 3> hslToRgb8(const float *hsl);
std::array<uint8_t, 3> hsvToRgb8(const float *hsv);

std::array<float, 3> hslToHsv(const float *hsl);
std::array<float, 3> hsvToHsl(const float *hsv);

} // namespace filter
} // namespace plugin
