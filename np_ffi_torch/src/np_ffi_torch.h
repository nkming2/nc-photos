#pragma once

#include <stdint.h>

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  uint8_t *pixel;
  unsigned width;
  unsigned height;
} TorchRgb8Image;

FFI_PLUGIN_EXPORT void torchRgb8ImageFree(TorchRgb8Image *that);

FFI_PLUGIN_EXPORT TorchRgb8Image *inferRealEsrgan(const TorchRgb8Image *input,
                                                  const char *modelPath);

FFI_PLUGIN_EXPORT TorchRgb8Image *inferNafnet(const TorchRgb8Image *input,
                                              const char *modelPath);

FFI_PLUGIN_EXPORT TorchRgb8Image *
inferEfficientDerain(const TorchRgb8Image *input, const char *modelPath);

#ifdef __cplusplus
}
#endif
