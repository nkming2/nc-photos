#include "pad_image.h"

#include <cassert>
#include <cstring>
#include <vector>

#include "util.h"

using namespace std;

namespace np_torch {

TorchRgb8Image *padImage(const TorchRgb8Image *srcImage, const unsigned padX,
                         const unsigned padY) {
  const auto topPad = padY / 2;
  const auto leftPad = padX / 2;
  const auto newWidth = srcImage->width + padX;
  const auto newHeight = srcImage->height + padY;
  const auto rightPad = newWidth - leftPad - srcImage->width;
  vector<uint8_t> pixel(newWidth * newHeight * 3);
  for (unsigned outY = 0; outY < newHeight; ++outY) {
    const auto srcY = [=]() {
      if (outY < topPad) {
        return 0U;
      } else if (outY >= topPad + srcImage->height) {
        return srcImage->height - 1;
      } else {
        return outY - topPad;
      }
    }();
    const uint8_t *srcRow = srcImage->pixel + srcY * srcImage->width * 3;
    uint8_t *dstRow = pixel.data() + outY * newWidth * 3;
    // l
    for (unsigned x = 0; x < leftPad; ++x) {
      dstRow[x * 3 + 0] = srcRow[0];
      dstRow[x * 3 + 1] = srcRow[1];
      dstRow[x * 3 + 2] = srcRow[2];
    }
    // mid
    memcpy(dstRow + leftPad * 3, srcRow, srcImage->width * 3);
    // r
    const uint8_t *rightPixel = srcRow + (srcImage->width - 1) * 3;
    for (unsigned x = 0; x < rightPad; ++x) {
      const auto i = (leftPad + srcImage->width + x) * 3;
      dstRow[i + 0] = rightPixel[0];
      dstRow[i + 1] = rightPixel[1];
      dstRow[i + 2] = rightPixel[2];
    }
  }
  return makeRgb8Image(pixel, newWidth, newHeight);
}

TorchRgb8Image *unpadImage(const TorchRgb8Image *srcImage, const unsigned padX,
                           const unsigned padY) {
  assert(srcImage->width >= padX);
  assert(srcImage->height >= padY);
  const auto topPad = padY / 2;
  const auto leftPad = padX / 2;
  const auto newWidth = srcImage->width - padX;
  const auto newHeight = srcImage->height - padY;
  return subImage(srcImage, leftPad, topPad, newWidth, newHeight);
}

} // namespace np_torch
