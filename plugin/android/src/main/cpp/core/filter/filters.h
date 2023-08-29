#include <cstddef>
#include <cstdint>
#include <vector>

namespace core {
namespace filter {

std::vector<uint8_t> applyBrightness(const uint8_t *rgba8, const size_t width,
                                     const size_t height, const float weight);

std::vector<uint8_t> applyWhitePoint(const uint8_t *rgba8, const size_t width,
                                     const size_t height, const float weight);

std::vector<uint8_t> applyBlackPoint(const uint8_t *rgba8, const size_t width,
                                     const size_t height, const float weight);

std::vector<uint8_t> applyContrast(const uint8_t *rgba8, const size_t width,
                                   const size_t height, const float weight);

std::vector<uint8_t> applySaturation(const uint8_t *rgba8, const size_t width,
                                     const size_t height, const float weight);

std::vector<uint8_t> applyTint(const uint8_t *rgba8, const size_t width,
                               const size_t height, const float weight);

std::vector<uint8_t> applyWarmth(const uint8_t *rgba8, const size_t width,
                                 const size_t height, const float weight);

} // namespace filter
} // namespace core
