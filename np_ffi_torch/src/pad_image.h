#pragma once

#include "np_ffi_torch.h"

namespace np_torch {

// Replication pad pixels to an image
TorchRgb8Image *padImage(const TorchRgb8Image *srcImage, const unsigned padX,
                         const unsigned padY);

// Remove padding pixels from an image
TorchRgb8Image *unpadImage(const TorchRgb8Image *srcImage, const unsigned padX,
                           const unsigned padY);

} // namespace np_torch
