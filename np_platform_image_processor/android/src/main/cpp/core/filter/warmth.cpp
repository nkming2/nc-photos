#include <cmath>
#include <cstdint>
#include <memory>
#include <vector>

#include "../log.h"
#include "curve.h"

using namespace core;
using namespace std;

namespace {

class Warmth {
public:
  std::vector<uint8_t> apply(const uint8_t *rgba8, const size_t width,
                             const size_t height, const float weight);

private:
  static filter::Curve getRCurve(const float weight);
  static unique_ptr<filter::Curve> getGCurve(const float weight);
  static filter::Curve getBCurve(const float weight);

  static constexpr const char *TAG = "Warmth";
};

inline uint8_t weighted(const uint8_t from, const uint8_t to,
                        const float weight) {
  return (to - from) * weight + from;
}

} // namespace

namespace core {
namespace filter {

vector<uint8_t> applyWarmth(const uint8_t *rgba8, const size_t width,
                            const size_t height, const float weight) {
  return Warmth().apply(rgba8, width, height, weight);
}

} // namespace filter
} // namespace core

namespace {

vector<uint8_t> Warmth::apply(const uint8_t *rgba8, const size_t width,
                              const size_t height, const float weight) {
  LOGI(TAG, "[apply] weight: %.2f", weight);
  if (weight == 0) {
    // shortcut
    return vector<uint8_t>(rgba8, rgba8 + width * height * 4);
  }
  const auto rCurve = getRCurve(weight);
  const auto gCurve = getGCurve(weight);
  const auto bCurve = getBCurve(weight);

  vector<uint8_t> output(width * height * 4);
#pragma omp parallel for
  for (size_t i = 0; i < width * height; ++i) {
    const auto p = i * 4;
    output[p + 0] = rCurve.fit(rgba8[p + 0]);
    output[p + 1] = gCurve ? gCurve->fit(rgba8[p + 1]) : rgba8[p + 1];
    output[p + 2] = bCurve.fit(rgba8[p + 2]);
    output[p + 3] = rgba8[p + 3];
  }
  return output;
}

filter::Curve Warmth::getRCurve(const float weight) {
  if (weight >= 0) {
    return filter::Curve({0, 78, 195, 255}, {0, weighted(78, 100, weight),
                                             weighted(195, 220, weight), 255});
  } else {
    return filter::Curve({0, 95, 220, 255},
                         {0, weighted(95, 60, std::abs(weight)),
                          weighted(220, 185, std::abs(weight)), 255});
  }
}

unique_ptr<filter::Curve> Warmth::getGCurve(const float weight) {
  if (weight >= 0) {
    return make_unique<filter::Curve>(
        vector<uint8_t>{0, 135, 255},
        vector<uint8_t>{0, weighted(135, 125, weight), 255});
  } else {
    return nullptr;
  }
}

filter::Curve Warmth::getBCurve(const float weight) {
  if (weight >= 0) {
    return filter::Curve({0, 95, 220, 255}, {0, weighted(95, 60, weight),
                                             weighted(220, 185, weight), 255});
  } else {
    return filter::Curve({0, 78, 195, 255},
                         {0, weighted(78, 100, std::abs(weight)),
                          weighted(195, 220, std::abs(weight)), 255});
  }
}

} // namespace
