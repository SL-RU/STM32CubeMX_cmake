set(STM32prog STM32_Programmer.sh -c port=SWD)
function(ADD_FLASH hex name)
  add_custom_target(flash_${name}
    DEPENDS ${hex}
    WORKING_DIRECTORY ${EXECUTABLE_OUTPUT_PATH}
    COMMENT "Flashing to STM32"
    COMMAND ${STM32prog} --verbosity 1 -rdu
    COMMAND ${STM32prog} -d ${hex}
    COMMAND ${STM32prog} -rst
    )
  add_custom_target(flash_protect_${name}
    DEPENDS ${hex}
    WORKING_DIRECTORY ${EXECUTABLE_OUTPUT_PATH}
    COMMENT "Flashing to STM32"
    COMMAND ${STM32prog} --verbosity 1 -rdu
    COMMAND ${STM32prog} -d ${hex}
    COMMAND ${STM32prog} -rst
    )
endfunction()
