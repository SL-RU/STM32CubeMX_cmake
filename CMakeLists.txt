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
# python3

# HOWTO:
# 1) Create STM32cubeMX SW4STM32 project.
# 2) Copy this CMakeLists.txt & CubeMX2_cmake.py in folder with created project.
# 3) Execute: "mkdir build; cd build"
# 4) Execute: "cmake ../; make"
# 5) DONE
cmake_minimum_required (VERSION 2.6)


#USER CUSTOM SETTINGS
#You can change values here. It's not recommended to change whole script
set(OPT "-O3")
set(USER_LINKER_FLAGS "-u _printf_float")
set(USER_CFLAGS "")
set(USER_COMPILER "Clang") # "Clang" or "GNU"
set(USER_DEBUG TRUE) # Or "False"

#You cam add your own defenitions
add_definitions(-DIS_STM32=1)
#add_definitions(-DYour_defenition=here)
#USER END

#CMAKE

#LOAD CUBE MX CONFIGURATION
#USING PYTHON SCRIPT CubeMX2_cmake.py
set(cubemx_dir ${CMAKE_CURRENT_LIST_DIR})
message("CubeMX dir: " ${cubemx_dir})
string(REPLACE " " "" cubemx_dir ${cubemx_dir})
execute_process(COMMAND bash "-c"
  "python3 ${cubemx_dir}/CubeMX2_cmake.py ${cubemx_dir}"
  OUTPUT_VARIABLE cubemx_conf
  RESULT_VARIABLE cubemx_res
  ERROR_VARIABLE  cubemx_err)
if(${cubemx_res} EQUAL "0")
  message("CubeMX ok")
else()
  message(FATAL_ERROR ${cubemx_err})
endif()

foreach(i ${cubemx_conf})
  message(${i})
endforeach()

#read IGNORE file and make list from it
file (STRINGS "CMakeIgnore.txt" CMAKE_IGNORE)
STRING(REGEX REPLACE "\n" ";" CMAKE_IGNORE "${CMAKE_IGNORE}")

list(GET cubemx_conf 0 STM32_PRJ_NAME     )
list(GET cubemx_conf 1 STM32_PRJ_CFLAGS   )
list(GET cubemx_conf 2 STM32_PRJ_DEFS     )
list(GET cubemx_conf 3 STM32_PRJ_MCU      )
list(GET cubemx_conf 4 STM32_PRJ_LD_SCRIPT)

message("CUBE project name: " ${STM32_PRJ_NAME})
message("CUBE MCU: "          ${STM32_PRJ_MCU})
message("CUBE CFLAGS: "       ${STM32_PRJ_CFLAGS})
message("CUBE DEFs: "         ${STM32_PRJ_DEFS})
message("CUBE LD script "     ${STM32_PRJ_LD_SCRIPT})

string(REPLACE " " "" STM32_PRJ_NAME ${STM32_PRJ_NAME})
string(REPLACE "\"" "" STM32_PRJ_DEFS ${STM32_PRJ_DEFS})
string(REPLACE " " ";" STM32_PRJ_DEFS ${STM32_PRJ_DEFS})
string(REPLACE " " "" STM32_PRJ_LD_SCRIPT ${STM32_PRJ_LD_SCRIPT})
string(REPLACE "\n" "" STM32_PRJ_LD_SCRIPT ${STM32_PRJ_LD_SCRIPT})
set(STM32_PRJ_LD_SCRIPT "${cubemx_dir}/${STM32_PRJ_LD_SCRIPT}")

if(POLICY CMP0012)
  cmake_policy(SET CMP0012 NEW)
endif()
cmake_policy(SET CMP0057 NEW)

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
        SET(dir_list ${dir_list} ${dir_path})
    ENDFOREACH()
    LIST(REMOVE_DUPLICATES dir_list)
    SET(${return_list} ${dir_list})
ENDMACRO()


#HEADERS
header_directories(INC)
include_directories(${INC})

#SOURCES
file(GLOB_RECURSE SRC RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.c)
string(REGEX REPLACE "[^;]*CMakeFiles/[^;]+;?" "" SRC "${SRC}")

#ASSEMBLER files
file(GLOB_RECURSE asm_SRC "*.s")
set_source_files_properties(${asm_SRC} "-x assembler-with-cpp")

#list all files
message("INCLUDES:")
set(incs "")
foreach(f ${INC})
  set(incs "${incs} -I${f}")
  message(${f})
endforeach()
message("SOURCES: ")
foreach(f ${SRC})
  message(${f})
  if (${f} IN_LIST CMAKE_IGNORE)
    list(REMOVE_ITEM SRC ${f})
    message("Ignored!")
  endif()
endforeach()
message("DEFINITIONS: ")
foreach(def ${STM32_PRJ_DEFS})
  message(${def})
  add_definitions("${def}")
endforeach()

#setup flags

set(CMAKE_C_FLAGS "${EXTERN_C_FLAGS} ${CMAKE_C_FLAGS} ${STM32_PRJ_CFLAGS} ${OPT} ${USER_CFLAGS}")
set(CMAKE_CXX_FLAGS "${EXTERN_C_FLAGS} ${CMAKE_CXX_FLAGS} ${STM32_PRJ_CFLAGS} ${OPT} ${USER_CFLAGS}")
set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} ${STM32_PRJ_CFLAGS} ${OPT} ${USER_CFLAGS}")


set(LDSCRIPT "-T${STM32_PRJ_LD_SCRIPT}")
set(LINKER_FLAGS "-specs=nosys.specs ${LDSCRIPT} -lc -lm -lnosys -Wl,--gc-sections ${STM32_PRJ_CFLAGS} ${OPT} ${USER_LINKER_FLAGS} ")
SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${LINKER_FLAGS}")


SET(TARGET ${CMAKE_PROJECT_NAME})
message(${CMAKE_C_COMPILER})

#setup targets
get_directory_property(C_DEFS COMPILE_DEFINITIONS)
#.elf
add_executable(${TARGET}.elf ${SRC} ${asm_SRC})
#print size
add_custom_command(TARGET ${TARGET}.elf POST_BUILD COMMAND ${CMAKE_SIZE} ${TARGET}.elf)

#other
ADD_CUSTOM_TARGET(${TARGET}.hex DEPENDS ${TARGET}.elf COMMAND ${CMAKE_OBJCOPY} -Oihex ${TARGET}.elf ${TARGET}.hex)
ADD_CUSTOM_TARGET(${TARGET}.bin DEPENDS ${TARGET}.elf COMMAND ${CMAKE_OBJCOPY} -Obinary ${TARGET}.elf ${TARGET}.bin)
