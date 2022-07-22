#include <algorithm>
#include <cstdint>
#include <vector>

#include "../lib/spline/spline.h"
#include "./curve.h"

using namespace std;

namespace {

std::vector<uint8_t> buildLut(const vector<uint8_t> &from,
                              const vector<uint8_t> &to);
vector<double> transformPoints(const vector<uint8_t> &pts);

} // namespace

namespace plugin {
namespace filter {

Curve::Curve(const vector<uint8_t> &from, const vector<uint8_t> &to)
    : lut(buildLut(from, to)) {}

} // namespace filter
} // namespace plugin

namespace {

std::vector<uint8_t> buildLut(const vector<uint8_t> &from,
                              const vector<uint8_t> &to) {
  assert(from.size() >= 2);
  assert(from[0] == 0);
  assert(from[from.size() - 1] == 255);
  assert(to.size() >= 2);
  assert(to[0] == 0);
  assert(to[to.size() - 1] == 255);
  tk::spline spline(transformPoints(from), transformPoints(to),
                    tk::spline::cspline_hermite);
  std::vector<uint8_t> lut;
  lut.reserve(256);
  for (int i = 0; i <= 0xFF; ++i) {
    lut.push_back(std::min(std::max(0, static_cast<int>(spline(i))), 0xFF));
  }
  return lut;
}

vector<double> transformPoints(const vector<uint8_t> &pts) {
  vector<double> product;
  product.reserve(pts.size());
  for (const auto pt : pts) {
    product.push_back(pt);
  }
  return product;
}

} // namespace
