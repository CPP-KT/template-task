include(FetchContent)

function(_ct_fetch_vcpkg)
  if (DEFINED ENV{CT_VCPKG_ROOT_DIR})
    message(STATUS "Detected CT_VCPKG_ROOT_DIR environment variable")
    set(CT_VCPKG_ROOT_DIR "$ENV{CT_VCPKG_ROOT_DIR}" CACHE FILEPATH "")
  endif()

  if(DEFINED CT_VCPKG_ROOT_DIR)
    message(STATUS "Using vcpkg at ${CT_VCPKG_ROOT_DIR}")
  else()
    message(STATUS "Fetching vcpkg...")
    FetchContent_Declare(
      vcpkg
      URL https://github.com/microsoft/vcpkg/archive/refs/tags/2025.02.14.tar.gz
    )
    FetchContent_MakeAvailable(vcpkg)

    set(CT_VCPKG_ROOT_DIR "${vcpkg_SOURCE_DIR}" CACHE FILEPATH "")
  endif()

  if(NOT DEFINED CT_VCPKG_TOOLCHAIN_FILE)
    set(CT_VCPKG_TOOLCHAIN_FILE "${CT_VCPKG_ROOT_DIR}/scripts/buildsystems/vcpkg.cmake" CACHE FILEPATH "")
  endif()
endfunction()

function(_ct_bootstrap_vcpkg)
  if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    set(CT_VCPKG_EXECUTABLE "${CT_VCPKG_ROOT_DIR}/vcpkg.exe")
    set(CT_VCPKG_BOOTSTRAP_SCRIPT "${CT_VCPKG_ROOT_DIR}/bootstrap-vcpkg.bat")
  else()
    set(CT_VCPKG_EXECUTABLE "${CT_VCPKG_ROOT_DIR}/vcpkg")
    set(CT_VCPKG_BOOTSTRAP_SCRIPT "${CT_VCPKG_ROOT_DIR}/bootstrap-vcpkg.sh")
  endif()

  if(NOT EXISTS "${CT_VCPKG_EXECUTABLE}")
    message(STATUS "Bootstrapping vcpkg before install")

    set(CT_VCPKG_BOOTSTRAP_LOG "${CMAKE_BINARY_DIR}/vcpkg-bootstrap.log")
    file(TO_NATIVE_PATH "${CT_VCPKG_BOOTSTRAP_LOG}" CT_NATIVE_VCPKG_BOOTSTRAP_LOG)
    execute_process(
      COMMAND "${CT_VCPKG_BOOTSTRAP_SCRIPT}" -disableMetrics
      OUTPUT_FILE "${CT_VCPKG_BOOTSTRAP_LOG}"
      ERROR_FILE "${CT_VCPKG_BOOTSTRAP_LOG}"
      RESULT_VARIABLE CT_VCPKG_BOOTSTRAP_RESULT)

    if(CT_VCPKG_BOOTSTRAP_RESULT EQUAL "0")
      message(STATUS "Bootstrapping vcpkg before install - done")
    else()
      message(STATUS "Bootstrapping vcpkg before install - failed")
      message(FATAL_ERROR "vcpkg install failed. See logs for more information: ${CT_NATIVE_VCPKG_BOOTSTRAP_LOG}")
    endif()
  endif()
endfunction()

option(CT_HARDENED "Should the standard library be hardened" OFF)
option(CT_SANITIZED "Should the build be sanitized" OFF)

function(_ct_generate_toolchain_and_triplet)
  cmake_path(GET CT_TOOLCHAIN_TEMPLATE STEM CT_TOOLCHAIN_NAME)
  set(CT_GENERATED_TOOLCHAIN_FILE "${CMAKE_BINARY_DIR}/gen/toolchains/${CT_TOOLCHAIN_NAME}.cmake")

  configure_file("${CT_TOOLCHAIN_TEMPLATE}" "${CT_GENERATED_TOOLCHAIN_FILE}" @ONLY)
  message(STATUS "Generated a toolchain '${CT_TOOLCHAIN_NAME}' from template")

  if(DEFINED CT_TRIPLET_TEMPLATE)
    message(STATUS "Running ${CT_VCPKG_ROOT_DIR}/vcpkg z-print-config")
    execute_process(
      COMMAND "${CT_VCPKG_ROOT_DIR}/vcpkg" z-print-config
      COMMAND_ERROR_IS_FATAL ANY
      OUTPUT_VARIABLE CT_VCPKG_CONFIG_OUTPUT
    )
    string(JSON CT_DEFAULT_TRIPLET_NAME GET "${CT_VCPKG_CONFIG_OUTPUT}" "default-triplet")
    set(CT_DEFAULT_TRIPLET_FILE "${CT_VCPKG_ROOT_DIR}/triplets/${CT_DEFAULT_TRIPLET_NAME}.cmake")

    cmake_path(GET CT_TRIPLET_TEMPLATE STEM CT_TRIPLET_TEMPLATE_NAME)
    set(CT_GENERATED_TRIPLETS_DIR "${CMAKE_BINARY_DIR}/gen/vcpkg-triplets")
    set(CT_GENERATED_TRIPLET_NAME "${CT_TRIPLET_TEMPLATE_NAME}-${CT_DEFAULT_TRIPLET_NAME}")
    set(CT_GENERATED_TRIPLET_FILE "${CT_GENERATED_TRIPLETS_DIR}/${CT_GENERATED_TRIPLET_NAME}.cmake")

    configure_file("${CT_TRIPLET_TEMPLATE}" "${CT_GENERATED_TRIPLET_FILE}" @ONLY)
    message(STATUS "Generated a vcpkg triplet '${CT_GENERATED_TRIPLET_NAME}' from template")

    set(VCPKG_TARGET_TRIPLET "${CT_GENERATED_TRIPLET_NAME}" CACHE STRING "")
    set(VCPKG_OVERLAY_TRIPLETS "${CT_GENERATED_TRIPLETS_DIR}" CACHE FILEPATH "")
  endif()
endfunction()

macro(ct_configure_vcpkg)
  _ct_fetch_vcpkg()
  _ct_bootstrap_vcpkg()
  _ct_generate_toolchain_and_triplet()
  include("${CT_VCPKG_TOOLCHAIN_FILE}")
endmacro()
