#include "np_ffi_torch.h"
#include <cstdlib>

void torchRgb8ImageFree(TorchRgb8Image *that) {
  if (that) {
    free(that->pixel);
  }
}

void torchRgba8ImageFree(TorchRgba8Image *that) {
  if (that) {
    free(that->pixel);
  }
}
