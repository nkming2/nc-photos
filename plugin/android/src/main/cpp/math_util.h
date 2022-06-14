#pragma once

#include <algorithm>

namespace plugin {

template <typename T> inline T clamp(const T &min, const T &x, const T &max) {
  return std::max(min, std::min(x, max));
}

} // namespace plugin
