### Requirements:

- cmake > 2.6
- arm-none-eabi-gdb
- clang

### HOWTO

1) Create STM32cubeMX Makefile project.
2) Copy this CMakeLists.txt & CMakeIgnore.txt & CMakeSetCompiler.txt in folder with created project.
3) Execute: "mkdir build; cd build"
4) Execute: "cmake ../; make"
5) DONE

# IMPORTANT

In cmsis_gcc.h replace line:
```
__ASM volatile ("VMSR fpscr, %0" : : "r" (fpscr) : "vfpcc");
```
with lines:
```
#ifdef __clang__
  __builtin_arm_set_fpscr(0xdeadbeef);
#else
  __ASM volatile ("VMSR fpscr, %0" : : "r" (fpscr) : "vfpcc");
#endif
```


LICENSE

    BSD 2-Clause License
                                                                                  
    Copyright (c) 2017, Alexander Lutsai <s.lyra@ya.ru>
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
                                                                                  
    * Redistributions of source code must retain the above copyright notice, this 
      list of conditions and the following disclaimer.
      
    * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
    
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
    FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
    SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
