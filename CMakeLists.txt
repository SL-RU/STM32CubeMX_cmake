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


#USER CUSTOM SETTINGS
#You can change values here. It's not recommended to change whole script
set(OPT "-O0")
set(USER_LINKER_FLAGS "-u _printf_float")
set(USER_CFLAGS "")

#You cam add your own defenitions
add_definitions(-DIS_STM32=1)
#add_definitions(-DYour_defenition=here)

#generate compile_commands.json
set(CMAKE_EXPORT_COMPILE_COMMANDS "ON")
#USER END

#CMAKE
cmake_minimum_required (VERSION 2.6)
include(CMakeForceCompiler)

# Targeting an embedded system, not OS.
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM Generic)
SET(CMAKE_SYSTEM_PROCESSOR arm)
SET(CMAKE_CROSSCOMPILING   1)

#CONFIGURE GCC TOOLCHAIN
SET(TOOL_EXECUTABLE_SUFFIX "")
SET(TOOLCHAIN_PREFIX   "/usr")
SET(TARGET_TRIPLET     "arm-none-eabi")
SET(TOOLCHAIN_BIN_DIR  ${TOOLCHAIN_PREFIX}/bin)
SET(TOOLCHAIN_INC_DIR  ${TOOLCHAIN_PREFIX}/${TARGET_TRIPLET}/include)
SET(TOOLCHAIN_LIB_DIR  ${TOOLCHAIN_PREFIX}/${TARGET_TRIPLET}/lib)

CMAKE_FORCE_C_COMPILER(arm-none-eabi-gcc GNU)
CMAKE_FORCE_CXX_COMPILER(arm-none-eabi-g++ GNU)
set(CMAKE_ASM_COMPILER ${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLET}-gcc${TOOL_EXECUTABLE_SUFFIX})

SET(CMAKE_OBJCOPY      ${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLET}-objcopy${TOOL_EXECUTABLE_SUFFIX} CACHE INTERNAL "objcopy tool")
SET(CMAKE_OBJDUMP      ${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLET}-objdump${TOOL_EXECUTABLE_SUFFIX} CACHE INTERNAL "objdump tool")
SET(CMAKE_SIZE         ${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLET}-size${TOOL_EXECUTABLE_SUFFIX} CACHE INTERNAL "size tool")
SET(CMAKE_DEBUGER      ${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLET}-gdb${TOOL_EXECUTABLE_SUFFIX} CACHE INTERNAL "debuger")

set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "") #remove -rdynamic
enable_language(C ASM)


#LOAD CUBE MX CONFIGURATION
#USING PYTHON SCRIPT CubeMX2_cmake.py
set(cubemx_dir ${CMAKE_CURRENT_LIST_DIR})
message("CubeMX dir: " ${cubemx_dir})
string(REPLACE " " "" cubemx_dir ${cubemx_dir})
execute_process(COMMAND bash "-c"
  "python ${cubemx_dir}/CubeMX2_cmake.py ${cubemx_dir}"
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

#start project
project(${STM32_PRJ_NAME})

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
endforeach()
message("DEFINITIONS: ")
foreach(def ${STM32_PRJ_DEFS})
  message(${def})
  add_definitions("${def}")
endforeach()

#setup flags
set(CMAKE_C_FLAGS "${STM32_PRJ_CFLAGS} ${OPT} -Wall -fdata-sections -ffunction-sections -std=c99 -g -gdwarf-2 ${USER_CFLAGS}")
set(LDSCRIPT "-T${STM32_PRJ_LD_SCRIPT}")
set(LINKER_FLAGS "-specs=nosys.specs ${LDSCRIPT} -lc -lm -lnosys -Wl,--gc-sections ${USER_LINKER_FLAGS}")
SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${LINKER_FLAGS}")


SET(TARGET ${CMAKE_PROJECT_NAME})

#setup targets
get_directory_property(C_DEFS COMPILE_DEFINITIONS)
#.elf
add_executable(${TARGET}.elf ${SRC} ${asm_SRC})
#print size
add_custom_command(TARGET ${TARGET}.elf POST_BUILD COMMAND ${CMAKE_SIZE} ${TARGET}.elf)

#other
ADD_CUSTOM_TARGET(${TARGET}.hex DEPENDS ${TARGET}.elf COMMAND ${CMAKE_OBJCOPY} -Oihex ${TARGET} ${TARGET}.hex)
ADD_CUSTOM_TARGET(${TARGET}.bin DEPENDS ${TARGET}.elf COMMAND ${CMAKE_OBJCOPY} -Obinary ${TARGET} ${TARGET}.bin)
