# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

# Project-level configuration.
set(PROJECT_NAME "sweph")
project(${PROJECT_NAME} VERSION 3.0.1+2.10.3 LANGUAGES CXX)

# Invoke the build for native code shared with the other target platforms.
# This can be changed to accomodate different builds.
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../native" "${CMAKE_CURRENT_BINARY_DIR}/shared")

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(sweph_bundled_libraries
  # Defined in ../native/CMakeLists.txt.
  # This can be changed to accomodate different builds.
  $<TARGET_FILE:sweph>
  PARENT_SCOPE
)
