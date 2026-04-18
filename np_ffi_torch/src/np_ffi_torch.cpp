#include "np_ffi_torch.h"
#include <cpuinfo.h>
#include <cstdint>

uint32_t getCoresCount() { return cpuinfo_get_cores_count(); }
