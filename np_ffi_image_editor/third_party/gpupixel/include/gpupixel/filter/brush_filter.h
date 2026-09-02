#pragma once

#include <array>
#include <cstdint>
#include <vector>
#include "gpupixel/filter/filter.h"

namespace gpupixel {

struct GPUPIXEL_API BrushStroke {
  // normalized coords
  std::vector<float> points;
  // rgba
  std::array<float, 4> color;
  // normalized to image width
  float radius;
};

class GPUPIXEL_API BrushFilter : public Filter {
 public:
  ~BrushFilter() override;

  static std::shared_ptr<BrushFilter> Create();
  bool Init();
  bool DoRender(bool updateSinks = true) override;

  void setStrokes(const std::vector<BrushStroke>& strokes);

 protected:
  BrushFilter() {};

 private:
  void rasterizeStrokes(const int width, const int height);
  void rasterizeSegment(const int width,
                        const int height,
                        const float ax,
                        const float ay,
                        const float bx,
                        const float by,
                        const float radiusPx,
                        const std::array<float, 4>& color);

  std::vector<BrushStroke> strokes_;

  std::vector<uint8_t> overlayPixels_;
  int overlayWidth_ = 0;
  int overlayHeight_ = 0;
  uint32_t overlayTexture_ = 0;
};

}  // namespace gpupixel
