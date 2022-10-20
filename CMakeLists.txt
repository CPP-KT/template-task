cmake_minimum_required(VERSION 3.21)
project(template)

set(CMAKE_CXX_STANDARD 20)

find_package(GTest REQUIRED)

add_executable(tests tests.cpp)

if (NOT MSVC)
  target_compile_options(tests PRIVATE -Wall -Wextra -Wshadow=compatible-local -Wno-sign-compare -pedantic)
endif()

option(USE_SANITIZERS "Enable to build with undefined,leak and address sanitizers" OFF)
if (USE_SANITIZERS)
  message(STATUS "Enabling sanitizers...")
  target_compile_options(tests PUBLIC -fsanitize=address,undefined,leak -fno-sanitize-recover=all)
  target_link_options(tests PUBLIC -fsanitize=address,undefined,leak)
endif()

target_link_libraries(tests GTest::gtest GTest::gtest_main)
