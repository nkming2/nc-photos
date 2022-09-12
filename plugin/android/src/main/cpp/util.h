#pragma once

#include <android/asset_manager.h>
#include <cstdint>
#include <functional>
#include <string>
#include <tensorflow/lite/c/c_api.h>
#include <vector>

namespace renderscript {
class RenderScriptToolkit;
}

namespace plugin {

template <typename T> class RaiiContainer {
public:
  RaiiContainer(const std::function<T *()> &constructor,
                const std::function<void(T *)> &destructor)
      : destructor(destructor) {
    obj = constructor();
  }

  ~RaiiContainer() {
    if (obj) {
      destructor(obj);
    }
  }

  T &operator*() { return *obj; }

  const T &operator*() const { return *obj; }

  T *operator->() { return obj; }

  const T *operator->() const { return obj; }

  T *get() { return obj; }

private:
  T *obj = nullptr;
  std::function<void(T *)> destructor;
};

class Asset {
public:
  Asset(AAssetManager *const aam, const std::string &name,
        const int mode = AASSET_MODE_BUFFER);
  Asset(const Asset &) = delete;
  Asset(Asset &&rhs);
  ~Asset();

  const void *getBuffer() const;
  const size_t getSize() const;

private:
  AAsset *asset = nullptr;
};

struct Coord {
  Coord() : Coord(0, 0) {}
  Coord(const int x, const int y) : x(x), y(y) {}

  const int x;
  const int y;
};

void initOpenMp();
int getNumberOfProcessors();

renderscript::RenderScriptToolkit &getToolkitInst();

std::string strprintf(const char *format, ...);
std::string toString(const TfLiteTensor &tensor);

std::vector<float> rgb8ToRgbFloat(const uint8_t *rgb, const size_t size,
                                  const bool shouldNormalize);
std::vector<uint8_t> rgbFloatToRgb8(const float *rgbF, const size_t size,
                                    const bool isNormalized);
std::vector<uint8_t> rgb8ToRgba8(const uint8_t *rgb8, const size_t width,
                                 const size_t height);
std::vector<uint8_t> rgba8ToRgb8(const uint8_t *rgba8, const size_t width,
                                 const size_t height);

template <size_t ch>
void replaceChannel(uint8_t *dst, const uint8_t *src, const size_t width,
                    const size_t height, const unsigned targetChannel) {
#pragma omp parallel for
  for (size_t y = 0; y < height; ++y) {
    for (size_t x = 0; x < width; ++x) {
      const auto i1 = y * width + x;
      const auto iN = i1 * ch;
      dst[iN + targetChannel] = src[i1];
    }
  }
}

void alphaBlend(const uint8_t *src, uint8_t *dst, const size_t width,
                const size_t height);

std::vector<uint8_t> argmax(const float *output, const size_t width,
                            const size_t height, const unsigned channel);

} // namespace plugin
