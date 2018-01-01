enable_language(ASM)
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)
#generate compile_commands.json
set(CMAKE_EXPORT_COMPILE_COMMANDS "ON")

# Configure the cross toolchain
if (CMAKE_C_COMPILER_ID STREQUAL "GNU")
  message("GCC!!!")
  if (DEFINED ENV{CROSS_COMPILE})
    message("111")
    set(CMAKE_C_COMPILER $ENV{CROSS_COMPILE}gcc)
    set(CMAKE_CXX_COMPILER $ENV{CROSS_COMPILE}g++)
    set(CMAKE_ASM_COMPILER $ENV{CROSS_COMPILE}gcc)
    set(CMAKE_OBJCOPY $ENV{CROSS_COMPILE}objcopy)
    set(CMAKE_SIZE $ENV{CROSS_COMPILE}size)
    set(CMAKE_AR $ENV{CROSS_COMPILE}ar)
  else()
    message("222")
    # Test if the cross-compilation toolchain is setup
    find_program(CROSS_COMPILE_GCC arm-none-eabi-gcc)
    if (NOT CROSS_COMPILE_GCC)
      message(FATAL_ERROR "Either add your cross-compilation toolchain to your PATH or define the environment variable CROSS_COMPILE.")
    endif()

    set(CMAKE_C_COMPILER arm-none-eabi-gcc)
    set(CMAKE_CXX_COMPILER arm-none-eabi-g++)
    set(CMAKE_ASM_COMPILER arm-none-eabi-gcc)
    set(CMAKE_OBJCOPY arm-none-eabi-objcopy)
    set(CMAKE_SIZE arm-none-eabi-size)
    set(CMAKE_AR arm-none-eabi-ar)
  endif()

  if(WIN32)
    # Redefine the linker command line as some GCC versions do not implement '--out-implib'
    set(CMAKE_C_LINK_EXECUTABLE "<CMAKE_C_COMPILER> <FLAGS> <CMAKE_C_LINK_FLAGS> <LINK_FLAGS> <OBJECTS>  -o <TARGET> <LINK_LIBRARIES>")
  endif()
elseif (CMAKE_C_COMPILER_ID STREQUAL "Clang")
  message("Clang!11")
  set(CMAKE_C_COMPILER "/usr/bin/clang")
  set(CMAKE_CXX_COMPILER "/usr/bin/clang")

  if (DEFINED ENV{CROSS_COMPILE})
    message("111")
    set(CMAKE_ASM_COMPILER $ENV{CROSS_COMPILE}gcc)
    set(CMAKE_OBJCOPY $ENV{CROSS_COMPILE}objcopy)
    set(CMAKE_SIZE $ENV{CROSS_COMPILE}size)
    # CMake generally calls CMAKE_C_COMPILER to link the executable. Clang invokes itself the linker installed on the host machine
    set(CMAKE_C_LINK_EXECUTABLE "$ENV{CROSS_COMPILE}gcc <CMAKE_C_LINK_FLAGS> <LINK_FLAGS> <OBJECTS>  -o <TARGET> <LINK_LIBRARIES>")
    set(CMAKE_CXX_LINK_EXECUTABLE "$ENV{CROSS_COMPILE}g++ <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS>  -o <TARGET> <LINK_LIBRARIES>")
    set(CROSS_COMPILE_GCC $ENV{CROSS_COMPILE}gcc)
  else()
    message("222")
    # Test if the cross-compilation toolchain is setup
    find_program(CROSS_COMPILE_GCC arm-none-eabi-gcc)
    if (NOT CROSS_COMPILE_GCC)
      message(FATAL_ERROR "Either add your cross-compilation toolchain to your PATH or define the environment variable CROSS_COMPILE.")
    endif()

    set(CMAKE_ASM_COMPILER arm-none-eabi-gcc)
    set(CMAKE_OBJCOPY arm-none-eabi-objcopy)
    set(CMAKE_SIZE arm-none-eabi-size)
    # CMake generally calls CMAKE_C_COMPILER to link the executable. Clang invokes itself the linker installed on the host machine
    set(CMAKE_C_LINK_EXECUTABLE "arm-none-eabi-gcc <CMAKE_C_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")
    set(CMAKE_CXX_LINK_EXECUTABLE "arm-none-eabi-g++ <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")
  endif()
else()
  message(FATAL_ERROR "${CMAKE_C_COMPILER_ID} Toolchain not supported")
endif()

if(WIN32)
  # Prevent Windows Standard Libraries to be added
  set(CMAKE_C_STANDARD_LIBRARIES "")
endif()

#
# Macro to get the list of include path of GCC
#
MACRO(GET_GCC_INCLUDE_PATH is_cxx gcc_path gcc_include_path)
  if (${is_cxx} STREQUAL "TRUE")
    if (WIN32)
      execute_process(COMMAND ${gcc_path} -v -x c++ -E NUL ERROR_VARIABLE _gcc_output OUTPUT_QUIET)
    else()
      execute_process(COMMAND ${gcc_path} -v -x c++ -E - INPUT_FILE /dev/null ERROR_VARIABLE _gcc_output OUTPUT_QUIET)
    endif()
  else()
    if (WIN32)
      execute_process(COMMAND ${gcc_path} -v -x c -E NUL ERROR_VARIABLE _gcc_output OUTPUT_QUIET)
    else()
      execute_process(COMMAND ${gcc_path} -v -x c -E - INPUT_FILE /dev/null ERROR_VARIABLE _gcc_output OUTPUT_QUIET)
    endif()
  endif()

  # Build an array of string from the GCC output
  string(REPLACE "\n" ";" _gcc_output "${_gcc_output}")

  set(_capture_include FALSE)
  set(_include_path "")

  # Go through the lines and capture between '"#include <...> search starts here:"' and 'End of search list.'
  foreach(_line ${_gcc_output})
    if(${_line} STREQUAL "End of search list.")
      set(_capture_include FALSE)
    endif()

    if(_capture_include)
      # Remove the leading and trailing empty characters
      string(REPLACE "\r" "" _line ${_line})
      string(SUBSTRING "${_line}" 1 -1 _line)

      set(_include_path "${_include_path} -I${_line}")
    endif()

    if(${_line} STREQUAL "#include <...> search starts here:")
      set(_capture_include TRUE)
    endif()
  endforeach()
  set(${gcc_include_path} ${_include_path})
ENDMACRO()

#
# Toolchain support
#
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -DDEBUG")
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -g -Wno-unused-variable")
if (CMAKE_C_COMPILER_ID STREQUAL "GNU")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=gnu99 -fno-common -fmessage-length=0 -Wall -fno-exceptions -ffunction-sections -fdata-sections -fomit-frame-pointer")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-common -fmessage-length=0 -Wall -fno-exceptions -ffunction-sections -fdata-sections -fomit-frame-pointer")
  set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} -x assembler-with-cpp")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--gc-sections")
  set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "")
  set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "")
elseif (CMAKE_C_COMPILER_ID STREQUAL "Clang")
  # Retrieve the GCC include paths for C and C++
  GET_GCC_INCLUDE_PATH(FALSE ${CROSS_COMPILE_GCC} CROSS_COMPILE_GCC_C_INCLUDE_PATH)
  GET_GCC_INCLUDE_PATH(TRUE ${CROSS_COMPILE_GCC} CROSS_COMPILE_GCC_CXX_INCLUDE_PATH)

  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -target arm-none-eabi -std=gnu99 -fno-common -fmessage-length=0 -Wall -fno-exceptions -ffunction-sections -fdata-sections -fomit-frame-pointer -fshort-enums ${CROSS_COMPILE_GCC_C_INCLUDE_PATH}")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -target arm-none-eabi -fno-common -fmessage-length=0 -Wall -fno-exceptions -ffunction-sections -fdata-sections -fomit-frame-pointer -fshort-enums ${CROSS_COMPILE_GCC_CXX_INCLUDE_PATH}")
  set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} -x assembler-with-cpp")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--gc-sections")
  set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "")
  set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "")
  set(EXTERN_C_FLAGS "-target arm-none-eabi")
  set(EXTERN_CXX_FLAGS "-target arm-none-eabi")

  # Prevent the warning related to non supported function attribute - see: https://sourceware.org/ml/newlib/2015/msg00714.html
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-unknown-attributes")
  set(EXTERN_C_FLAGS "${EXTERN_C_FLAGS} -Wno-unknown-attributes ${CROSS_COMPILE_GCC_C_INCLUDE_PATH}")
else()
  message(FATAL_ERROR "${CMAKE_C_COMPILER_ID} Toolchain not supported")
endif()
