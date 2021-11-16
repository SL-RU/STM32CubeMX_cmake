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

macro(GLOB_SOURCES root_directory target_name SRC_makefile ASM_SRC_makefile INC_makefile)
  # Read ignore file and make list from it
  file (STRINGS "${root_directory}/CMakeIgnore.txt" ignore_file_path)
  STRING(REGEX REPLACE "\n" ";" ignore_file_path "${ignore_file_path}")
  set(ignore_pattern "")
  foreach(f ${ignore_file_path})
    string(STRIP ${f} f)
    set(ignore_pattern "${ignore_pattern};${f}")
  endforeach()

  FILE(GLOB_RECURSE new_list RELATIVE ${root_directory} *.h)
  SET(INC "")
  foreach(file_path ${new_list})
    GET_FILENAME_COMPONENT(dir_path ${file_path} PATH)
    string(REPLACE "${root_directory}/" "" dir_path ${dir_path})
    set(INC "${INC};${dir_path}")
  endforeach()

  FILE(GLOB_RECURSE ASM_SRC RELATIVE ${root_directory} *.s)
  FILE(GLOB_RECURSE SRC RELATIVE ${root_directory} *.c)
  string(REGEX REPLACE "[^;]*CMakeFiles/[^;]+;?" "" SRC "${SRC}")
  #Apply ignore pattern
  foreach(f ${INC})
    foreach(i ${ignore_pattern})
      if (${f} MATCHES ${i})
        list(REMOVE_ITEM INC ${f})
      endif()
    endforeach()
  endforeach()
  foreach(f ${SRC})
    foreach(i ${ignore_pattern})
      if (${f} MATCHES ${i})
        list(REMOVE_ITEM SRC ${f})
      endif()
    endforeach()
  endforeach()
  foreach(f ${ASM_SRC})
    foreach(i ${ignore_pattern})
      if (${f} MATCHES ${i})
        list(REMOVE_ITEM ASM_SRC ${f})
      endif()
    endforeach()
  endforeach()

  set(SRC "${SRC_makefile};${SRC}")
  set(ASM_SRC "${ASM_SRC_makefile};${ASM_SRC}")
  set(INC "${INC_makefile};${INC}")
  LIST(REMOVE_DUPLICATES INC)
  LIST(REMOVE_DUPLICATES SRC)
  LIST(REMOVE_DUPLICATES ASM_SRC)
  
  target_include_directories(${TARGET} PUBLIC ${INC})
  target_sources(${TARGET} PRIVATE ${SRC} ${ASM_SRC})
endmacro()
