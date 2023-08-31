#include <cstdint>
#include <deque>
#include <vector>

namespace im_proc {

class ImageTile {
public:
  ImageTile();
  ImageTile(std::vector<uint8_t> &&data, const size_t width,
            const size_t height, const unsigned channel);

  ImageTile &operator=(const ImageTile &) = delete;
  ImageTile &operator=(ImageTile &&rhs);

  const std::vector<uint8_t> &data() const { return _data; }
  size_t width() const { return _width; }
  size_t height() const { return _height; }
  unsigned channel() const { return _channel; }

private:
  std::vector<uint8_t> _data;
  size_t _width;
  size_t _height;
  unsigned _channel;
};

/**
 * Split an image to smaller tiles with optional padding
 *
 * If padding > 0, each tile will have extra pixels belonging to the previous
 * tiles in both axis
 */
class ImageSplitter {
public:
  ImageSplitter(const size_t tileWidth, const size_t tileHeight)
      : ImageSplitter(tileWidth, tileHeight, 0) {}
  ImageSplitter(const size_t tileWidth, const size_t tileHeight,
                const size_t padding);

  std::deque<std::deque<ImageTile>> operator()(const uint8_t *image,
                                               const size_t width,
                                               const size_t height,
                                               const unsigned channel) const;

private:
  const size_t _tileWidth;
  const size_t _tileHeight;
  const size_t _padding;

  static constexpr const char *TAG = "ImageSplitter";
};

} // namespace im_proc
