#pragma once

#include "gpupixel_composite.h"
#include <vector>

namespace np_image_editor {
namespace edit {

class Brush : public GpupixelEdit {
public:
  typedef gpupixel::BrushStroke Stroke;

  explicit Brush(std::vector<Stroke> strokes) : strokes_(std::move(strokes)) {}

  std::shared_ptr<gpupixel::Source>
  addSink(gpupixel::Source *src) const override;

private:
  const std::vector<Stroke> strokes_;
};

} // namespace edit
} // namespace np_image_editor
