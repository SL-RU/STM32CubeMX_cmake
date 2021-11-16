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


# Read variables from Makefile
macro(ADD_EXECUTABLE_FROM_MAKEFILE MKFile)
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
    string(STRIP ${value} value)
    string(STRIP ${var_name} var_name)
    set(MK_${var_name} ${value})
  endforeach()

  #INCLUDES from Makefile
  string(REPLACE " " ";" MK_C_INCLUDES ${MK_C_INCLUDES})
  foreach(f ${MK_C_INCLUDES})
    string(STRIP ${f} f)
    string(REGEX REPLACE "^-I" "" f ${f})
    set(INC ${INC} ${f})
  endforeach()

  #SOURCES from Makefile
  string(REPLACE " " ";" MK_C_SOURCES ${MK_C_SOURCES})
  set(SRC "${SRC};${MK_C_SOURCES}")
  list(REMOVE_DUPLICATES SRC)

  #ASSEMBLER from Makefile
  string(REPLACE " " ";" MK_ASM_SOURCES ${MK_ASM_SOURCES})
  set(ASM_SRC "${ASM_SRC};${MK_ASM_SOURCES}")
  list(REMOVE_DUPLICATES ASM_SRC)
  set_source_files_properties(${ASM_SRC} DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    PROPERTIES -x assembler-with-cpp)

  set(STM32_PRJ_NAME      ${MK_TARGET})
  set(STM32_PRJ_CFLAGS    ${MK_CPU} ${MK_FPU} ${MK_FLOAT-ABI})
  set(STM32_PRJ_DEFS      ${MK_C_DEFS})
  set(STM32_PRJ_MCU       ${MK_MCU})
  set(STM32_PRJ_LD_SCRIPT "${CMAKE_CURRENT_LIST_DIR}/${MK_LDSCRIPT}")

  message("CUBE Project name: " ${MK_TARGET})
  set(TARGET ${MK_TARGET}.elf)
  add_executable(${TARGET})
  target_compile_definitions(${TARGET} PUBLIC ${STM32_PRJ_DEFS})
  target_compile_options(${TARGET} BEFORE PRIVATE $<$<COMPILE_LANGUAGE:C>: ${STM32_PRJ_CFLAGS}>)
  target_compile_options(${TARGET} BEFORE PRIVATE $<$<COMPILE_LANGUAGE:ASM>: -x assembler-with-cpp ${STM32_PRJ_CFLAGS}>)
endmacro()
