project("stm32_project")
cmake_minimum_required(VERSION 3.20)
SET(CMAKE_PROJECT_VERSION 1.0)
SET(CMAKE_EXPORT_COMPILE_COMMANDS TRUE)
# Enable some policies
if(POLICY CMP0007)
  cmake_policy(SET CMP0007 NEW)
endif()
if(POLICY CMP0012)
  cmake_policy(SET CMP0012 NEW)
endif()
cmake_policy(SET CMP0057 NEW)
cmake_policy(SET CMP0076 NEW)

#SET(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR})

SET(TARGET_GROUP test CACHE STRING "What Should I Build?")

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type. Debug or Release" FORCE)
  message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
endif()

set(CMAKE_VERBOSE_MAKEFILE OFF)

set(VVERSION DEBUG CACHE STRING "Is debug mode")
set(IVERSION 666 CACHE  STRING "Integer version")

set(CMAKE_C_COMPILER_ID "Clang")

include("cmake/CMakeSetCompiler.cmake")
include("cmake/GlobSrcAndHeaders.cmake")
include("cmake/STM32CommonTarget.cmake")
include("cmake/ExecutableFromMakefile.cmake")
include("cmake/STM32_flash.cmake")

SET(STM32_C_COMMON_FLAGS
  -std=gnu17
  -dM
  -Wall
  -mthumb
  -fno-common
  -fomit-frame-pointer
  -ffunction-sections -fdata-sections
  -Wenum-conversion
  -fshort-enums
  )
SET(STM32_LINK_COMMON_FLAGS
  -specs=nosys.specs
  -Wl,--gc-sections
  -u _printf_float
  -Wl,--print-memory-usage
  ${STM32_C_COMMON_FLAGS}
  )

set(CMAKE_C_FLAGS_DEBUG "-DDEBUG -g -gdwarf-2 -Og")
set(CMAKE_C_FLAGS_RELEASE "-Ofast")

ADD_STM32_COMMON_TARGET()

#ADD_FLASH("name_of_project.hex" "name")

if(CMAKE_BUILD_TYPE STREQUAL "Release")
  
endif()
