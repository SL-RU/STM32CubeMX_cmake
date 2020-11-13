# BSD 2-Clause License
# 
# Copyright (c) 2017, Alexander Lutsai <s.lyra@ya.ru>
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# 
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Requirements:
# cmake > 2.6
# arm-none-eabi-gdb

# HOWTO:
# 1) Create STM32cubeMX Makefile project.
# 2) Copy this CMakeLists.txt & CMakeIgnore.txt & CMakeSetCompiler.txt in folder with created project.
# 3) Execute: "mkdir build; cd build"
# 4) Execute: "cmake ../; make"
# 5) DONE
cmake_minimum_required (VERSION 2.6)

# USER REGION BEGIN
set(OPT "-O0")
set(USER_LINKER_FLAGS "-u _printf_float -Wl,--print-memory-usage")
set(USER_CFLAGS "")
set(USER_COMPILER "Clang") # "Clang" or "GNU"
set(USER_DEBUG TRUE) # Or "False"
set(USER_INC "")
set(USER_SRC "")

# USER REGION END


# Enable some policies
if(POLICY CMP0007)
  cmake_policy(SET CMP0007 NEW)
endif()
if(POLICY CMP0012)
  cmake_policy(SET CMP0012 NEW)
endif()
cmake_policy(SET CMP0057 NEW)
set(CMAKE_VERBOSE_MAKEFILE OFF)

# Read ignore file and make list from it
file (STRINGS "${CMAKE_CURRENT_LIST_DIR}/CMakeIgnore.txt" CMAKE_IGNORE_s)
STRING(REGEX REPLACE "\n" ";" CMAKE_IGNORE_s "${CMAKE_IGNORE_s}")
set(CMAKE_IGNORE "")
#message("IGNORE: ")
foreach(f ${CMAKE_IGNORE_s})
  string(STRIP ${f} f)
  set(CMAKE_IGNORE "${CMAKE_IGNORE};${f}")
  #message(${f})
endforeach()

# Read variables from Makefile
function(ReadVariables MKFile)
  file(READ "${MKFile}" FileContents)
  string(REPLACE "\\\n" "" FileContents ${FileContents})
  string(REPLACE "\n" ";" FileLines ${FileContents})
  list(REMOVE_ITEM FileLines "")
  foreach(line ${FileLines})
    string(FIND ${line} "=" loc )
    list(LENGTH line_split count)
    if (loc LESS 2)
      #message(STATUS "Skipping ${line}")
      continue()
    endif()
    string(SUBSTRING ${line} 0 ${loc} var_name)
    math(EXPR loc "${loc} + 1")
    string(SUBSTRING ${line} ${loc} -1 value)
    #message("parse ${loc} ${var_name} ${value}")
    string(STRIP ${value} value)
    #separate_arguments(value)
    #list(REMOVE_AT line_split -1)
    #foreach(var_name ${line_split})
    string(STRIP ${var_name} var_name)
    set(MK_${var_name} ${value} PARENT_SCOPE)
    #endforeach()
  endforeach()
endfunction()
ReadVariables("Makefile")

set(STM32_PRJ_NAME      ${MK_TARGET})
set(STM32_PRJ_CFLAGS    "${MK_CPU} -mthumb ${MK_FPU} ${MK_FLOAT-ABI} ${USER_CFLAGS} ${OPT} -Wall -fdata-sections -ffunction-sections -dM -fno-common")
set(STM32_PRJ_DEFS      "${MK_C_DEFS}")
set(STM32_PRJ_MCU       ${MK_MCU})
set(STM32_PRJ_LD_SCRIPT "${CMAKE_CURRENT_LIST_DIR}/${MK_LDSCRIPT}")

message("CUBE Project name: " ${STM32_PRJ_NAME})


project(${STM32_PRJ_NAME})
set(CMAKE_C_COMPILER_ID ${USER_COMPILER})
if(${USER_DEBUG})
  set(CMAKE_BUILD_TYPE "Debug")
else(${USER_DEBUG})
  set(CMAKE_BUILD_TYPE "Release")
endif(${USER_DEBUG})

include("CMakeSetCompiler.cmake")

#find and add all headers & sources & asm to target
MACRO(HEADER_DIRECTORIES return_list)
  FILE(GLOB_RECURSE new_list *.h)
  SET(dir_list "")
  FOREACH(file_path ${new_list})
    GET_FILENAME_COMPONENT(dir_path ${file_path} PATH)
    string(REPLACE "${CMAKE_CURRENT_LIST_DIR}/" "" dir_path ${dir_path})
    SET(dir_list ${dir_list} ${dir_path})
  ENDFOREACH()
  LIST(REMOVE_DUPLICATES dir_list)
  SET(${return_list} ${dir_list})
ENDMACRO()


#HEADERS
header_directories(INC)
set(INC ${INC} ${USER_INC})

#SOURCES
file(GLOB_RECURSE SRC RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.c)
string(REGEX REPLACE "[^;]*CMakeFiles/[^;]+;?" "" SRC "${SRC}")

#ASSEMBLER files
file(GLOB_RECURSE ASM_SRC RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "*.s")

#Apply ignore pattern
foreach(f ${INC})
  foreach(i ${CMAKE_IGNORE})
    if (${f} MATCHES ${i})
      list(REMOVE_ITEM INC ${f})
    endif()
  endforeach()
endforeach()
foreach(f ${SRC})
  foreach(i ${CMAKE_IGNORE})
    if (${f} MATCHES ${i})
      list(REMOVE_ITEM SRC ${f})
    endif()
  endforeach()
endforeach()
foreach(f ${ASM_SRC})
  foreach(i ${CMAKE_IGNORE})
    if (${f} MATCHES ${i})
      list(REMOVE_ITEM ASM_SRC ${f})
    endif()
  endforeach()
endforeach()

#DEFENITIONS
macro(TIME RESULT)
  execute_process(COMMAND "date" "+%y%m%d%H%M" OUTPUT_VARIABLE ${RESULT})
endmacro()
TIME(VVERSION)
string(REPLACE "\n" "" VVERSION ${VVERSION})
add_definitions(-DVERSION="${VVERSION}")

set(STM32_PRJ_DEFS "${STM32_PRJ_DEFS}")
add_definitions("${STM32_PRJ_DEFS}")


#INCLUDES from Makefile
string(REPLACE " " ";" MK_C_INCLUDES ${MK_C_INCLUDES})
foreach(f ${MK_C_INCLUDES})
  string(STRIP ${f} f)
  string(REGEX REPLACE "^-I" "" f ${f})
  set(INC "${INC};${f}")
endforeach()
include_directories(${INC})

#SOURCES from Makefile
string(REPLACE " " ";" MK_C_SOURCES ${MK_C_SOURCES})
set(SRC "${SRC};${MK_C_SOURCES}")
list(REMOVE_DUPLICATES SRC)


#ASSEMBLER from Makefile
string(REPLACE " " ";" MK_ASM_SOURCES ${MK_ASM_SOURCES})
set(ASM_SRC "${ASM_SRC};${MK_ASM_SOURCES}")
list(REMOVE_DUPLICATES ASM_SRC)
set_source_files_properties(${ASM_SRC} "-x assembler-with-cpp")


#list all files
message("INCLUDES:")
foreach(f ${INC})
  message(${f})
endforeach()
message("SOURCES: ")
foreach(f ${SRC})
  message(${f})
endforeach()
message("ASM_SOURCES: ")
foreach(f ${ASM_SRC})
  message(${f})
endforeach()
message("DEFINITIONS: ")
message("${STM32_PRJ_DEFS}")

#setup flags
set(CMAKE_C_FLAGS_WARN "-dM -fno-common -Wall -ffunction-sections -fdata-sections -fomit-frame-pointer")
set(CMAKE_C_FLAGS "${STM32_PRJ_CFLAGS} ${EXTERN_C_FLAGS} --target=arm-none-eabi")
set(CMAKE_CXX_FLAGS "${STM32_PRJ_CFLAGS} ${EXTERN_CXX_FLAGS} --target=arm-none-eabi")
set(CMAKE_ASM_FLAGS "-x assembler-with-cpp ${STM32_PRJ_CFLAGS}")
set(CMAKE_C_FLAGS_DEBUG "-DDEBUG -g -gdwarf-2")

set(CMAKE_EXE_LINKER_FLAGS "-specs=nosys.specs -T${STM32_PRJ_LD_SCRIPT} ${MK_LIBS} -Wl,--gc-sections ${USER_LINKER_FLAGS} ${STM32_PRJ_CFLAGS}")
#set(CMAKE_MODULE_LINKER_FLAGS "")
#set(CMAKE_SHARED_LINKER_FLAGS "")
#set(CMAKE_STATIC_LINKER_FLAGS "")


SET(TARGET ${CMAKE_PROJECT_NAME})

#setup targets
#.elf
add_executable(${TARGET}.elf ${SRC} ${ASM_SRC} ${USER_SRC})
#print size
add_custom_command(TARGET ${TARGET}.elf POST_BUILD COMMAND ${CMAKE_SIZE} --common ${TARGET}.elf)
#make .hex & .bin
add_custom_command(TARGET ${TARGET}.elf POST_BUILD COMMAND ${CMAKE_OBJCOPY} -Oihex ${TARGET}.elf ${TARGET}.hex)
add_custom_command(TARGET ${TARGET}.elf POST_BUILD COMMAND ${CMAKE_OBJCOPY} -Obinary ${TARGET}.elf ${TARGET}.bin)
