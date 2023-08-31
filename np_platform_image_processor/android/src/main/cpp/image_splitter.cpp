#include <cmath>
#include <cstdint>
#include <cstring>
#include <deque>
#include <vector>

#include "image_splitter.h"
#include "log.h"
#include "util.h"

using namespace std;

namespace im_proc {

ImageTile::ImageTile() : _width(0), _height(0), _channel(3) {}

ImageTile::ImageTile(vector<uint8_t> &&data, const size_t width,
                     const size_t height, const unsigned channel)
    : _data(move(data)), _width(width), _height(height), _channel(channel) {}

ImageTile &ImageTile::operator=(ImageTile &&rhs) {
  if (this != &rhs) {
    _data = move(rhs._data);
    _width = rhs._width;
    rhs._width = 0;
    _height = rhs._height;
    rhs._height = 0;
    _channel = rhs._channel;
  }
  return *this;
}

ImageSplitter::ImageSplitter(const size_t tileWidth, const size_t tileHeight,
                             const size_t padding)
    : _tileWidth(tileWidth), _tileHeight(tileHeight), _padding(padding) {}

deque<deque<ImageTile>>
ImageSplitter::operator()(const uint8_t *image, const size_t width,
                          const size_t height, const unsigned channel) const {
  const size_t tileHoriz = ceil(static_cast<float>(width) / _tileWidth);
  const size_t tileVert = ceil(static_cast<float>(height) / _tileHeight);
  deque<deque<ImageTile>> product(tileVert);
  for (auto &r : product) {
    for (int i = 0; i < tileHoriz; ++i) {
      r.emplace_back();
    }
  }
  LOGD(TAG, "[split] Spliting %zux%zu into %zux%zu tiles, each %zux%zu in size",
       width, height, tileHoriz, tileVert, _tileWidth, _tileHeight);

  for (size_t ty = 0; ty < tileVert; ++ty) {
    const size_t thisTilePaddingY = ty == 0 ? 0 : _padding;
    const size_t thisTileH =
        std::min(_tileHeight, height - _tileHeight * ty) + thisTilePaddingY;
    for (size_t tx = 0; tx < tileHoriz; ++tx) {
      const size_t thisTilePaddingX = tx == 0 ? 0 : _padding;
      const size_t thisTileW =
          std::min(_tileWidth, width - _tileWidth * tx) + thisTilePaddingX;
      LOGI(TAG, "[split] Tile[%zu][%zu]: %zux%zu", ty, tx, thisTileW,
           thisTileH);
      vector<uint8_t> tile(thisTileW * thisTileH * channel);
      for (size_t dy = 0; dy < thisTileH; ++dy) {
        const auto srcOffset =
            ((ty * _tileHeight + dy - thisTilePaddingY) * width +
             (tx * _tileWidth - thisTilePaddingX)) *
            channel;
        const auto dstOffset = dy * thisTileW * channel;
        memcpy(tile.data() + dstOffset, image + srcOffset, thisTileW * channel);
      }
      product[ty][tx] = ImageTile(move(tile), thisTileW, thisTileH, channel);
    }
  }
  return product;
}

} // namespace im_proc
