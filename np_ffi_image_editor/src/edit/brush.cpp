#include "brush.h"
#include <gpupixel/filter/brush_filter.h>
#include <gpupixel/gpupixel.h>

using namespace gpupixel;
using namespace std;

namespace np_image_editor {
namespace edit {

shared_ptr<Source> Brush::addSink(Source *src) const {
  auto filter = BrushFilter::Create();
  filter->setStrokes(strokes_);
  return src->AddSink(filter);
}

} // namespace edit
} // namespace np_image_editor
