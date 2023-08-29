#include <cstdint>
#include <vector>

namespace core {
namespace filter {

class Saturation {
public:
  std::vector<uint8_t> apply(const uint8_t *rgba8, const size_t width,
                             const size_t height, const float weight);

private:
  static constexpr const char *TAG = "Saturation";
};

} // namespace filter
} // namespace core
