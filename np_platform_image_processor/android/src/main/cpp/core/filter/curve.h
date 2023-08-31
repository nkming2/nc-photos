#include <cstdint>
#include <vector>

namespace core {
namespace filter {

class Curve {
public:
  /**
   * Construct a curve that fit values from @a from to @a to
   * @param from Control points, must be sorted, must begins with 0 and ends
   * with 255
   * @param to
   */
  Curve(const std::vector<uint8_t> &from, const std::vector<uint8_t> &to);
  Curve(const Curve &) = default;
  Curve(Curve &&) = default;

  uint8_t fit(const uint8_t from) const { return lut[from]; }

private:
  std::vector<uint8_t> lut;
};

} // namespace filter
} // namespace core
