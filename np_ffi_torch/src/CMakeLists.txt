cmake_minimum_required(VERSION 3.18.1)

project(np_ffi_torch_library VERSION 0.0.1 LANGUAGES C CXX)
set(CMAKE_CXX_STANDARD 20)

if (ANDROID)
  find_library(log-lib log)
  find_library(android-lib android)
endif()

set(Python3_EXECUTABLE "${CMAKE_CURRENT_SOURCE_DIR}/../third_party/executorch_build/bin/python3")
set(EXECUTORCH_HOME_DIR "${CMAKE_SOURCE_DIR}/../third_party/executorch")
set(EXECUTORCH_BUILD_PRESET_FILE ${EXECUTORCH_HOME_DIR}/tools/cmake/preset/android.cmake)
set(EXECUTORCH_BUILD_ANDROID_JNI OFF)
set(EXECUTORCH_LOG_LEVEL error)
set(EXECUTORCH_BUILD_DEVTOOLS OFF)
set(EXECUTORCH_BUILD_EXTENSION_LLM OFF)
set(EXECUTORCH_BUILD_EXTENSION_LLM_RUNNER OFF)
set(EXECUTORCH_BUILD_EXTENSION_TRAINING OFF)
set(EXECUTORCH_BUILD_VULKAN ON)

# Always build executorch in Release mode regardless of the project build type
set(_saved_build_type "${CMAKE_BUILD_TYPE}")
set(CMAKE_BUILD_TYPE "Release")
add_subdirectory(${EXECUTORCH_HOME_DIR} "${CMAKE_CURRENT_SOURCE_DIR}/../third_party/executorch_build/cmake-out")
set(CMAKE_BUILD_TYPE "${_saved_build_type}")

add_library(np_ffi_torch SHARED
  "efficient_derain/efficient_derain.cpp"
  "efficient_sam/efficient_sam_extract.cpp"
  "efficient_sam/efficient_sam.cpp"
  "nafnet/nafnet.cpp"
  "neurop/neurop.cpp"
  "real_esrgan/real_esrgan.cpp"
  "zero_dce/zero_dce.cpp"
  "memory_context.cpp"
  "model_loader.cpp"
  "np_ffi_torch.cpp"
  "pad_image.cpp"
  "stopwatch.cpp"
  "util.cpp"
)

add_compile_options(
  -Wall
)

set_target_properties(np_ffi_torch PROPERTIES
  PUBLIC_HEADER np_ffi_torch.h
  OUTPUT_NAME "np_ffi_torch"
)

target_include_directories(
  np_ffi_torch
  PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/../third_party/single-header-image-resampler"
)
target_link_libraries(
  np_ffi_torch
  PRIVATE
  ${log-lib}
  ${android-lib}
  executorch
  executorch::extensions
  executorch::backends
  # executorch::kernels
  quantized_ops_lib
  optimized_native_cpu_ops_lib
  -fopenmp -static-openmp
)
target_compile_definitions(np_ffi_torch PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(np_ffi_torch PRIVATE "-Wl,-z,max-page-size=16384")
endif()
