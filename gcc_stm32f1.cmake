SET(STM32_CMAKE_XXX_COMPILER_FLAGS "-mthumb -mcpu=cortex-m3")
SET(STM32_CMAKE_XXX_LINKER_FLAGS "-mthumb -mcpu=cortex-m3")

SET(STM32_CHIP_TYPE_REGEXP "10[012357].[468BCDE]")
SET(STM32_CHIP_TYPES CL HD HD_VL MD MD_VL LD LD_VL XL CACHE INTERNAL "stm32f1 chip types")
SET(STM32_CODES "10[57]" "10[13].[CDE]" "100.[CDE]" "10[123].[8B]" "100.[8B]" "10[123].[46]" "100.[46]" "10[13].[FG]")

MACRO(STM32_GET_CHIP_PARAMETERS CHIP FLASH_SIZE RAM_SIZE)
    STRING(REGEX REPLACE "^[sS][tT][mM]32[fF](10[012357]).[468BCDE]" "\\1" STM32_CODE ${CHIP})
    STRING(REGEX REPLACE "^[sS][tT][mM]32[fF]10[012357].([468BCDE])" "\\1" STM32_SIZE_CODE ${CHIP})

    STM32FX_GET_CHIP_FLASH_SIZE(${STM32_SIZE_CODE} ${FLASH_SIZE})
    
    STM32_GET_CHIP_TYPE(${CHIP} TYPE)
    
    IF(${TYPE} STREQUAL "XL")
        SET(RAM "80K")
    ELSEIF(${TYPE} STREQUAL "CL")
        SET(RAM "64K")
    ELSEIF((${TYPE} STREQUAL "LD") AND ((STM32_CODE STREQUAL "102") OR (STM32_CODE STREQUAL "101")))
        IF(STM32_SIZE_CODE STREQUAL "4")
            SET(RAM "4K")
        ELSE()
            SET(RAM "6K")
        ENDIF()
    ELSEIF(${TYPE} STREQUAL "LD")
        IF(STM32_SIZE_CODE STREQUAL "4")
            SET(RAM "6K")
        ELSE()
            SET(RAM "10K")
        ENDIF()
    ELSEIF(${TYPE} STREQUAL "LD_VL")
        SET(RAM "4K")
    ELSEIF((${TYPE} STREQUAL "MD") AND ((STM32_CODE STREQUAL "102") OR (STM32_CODE STREQUAL "101")))
        IF(STM32_SIZE_CODE STREQUAL "8")
            SET(RAM "10K")
        ELSE()
            SET(RAM "16K")
        ENDIF()
    ELSEIF(${TYPE} STREQUAL "MD")
        SET(RAM "20K")
    ELSEIF(${TYPE} STREQUAL "MD_VL")
        SET(RAM "8K")
    ELSEIF((${TYPE} STREQUAL "HD") AND (STM32_CODE STREQUAL "101"))
        IF(STM32_SIZE_CODE STREQUAL "C")
            SET(RAM "32K")
        ELSE()
            SET(RAM "48K")
        ENDIF()
    ELSEIF(${TYPE} STREQUAL "HD")
        IF(STM32_SIZE_CODE STREQUAL "C")
            SET(RAM "48K")
        ELSE()
            SET(RAM "64K")
        ENDIF()
    ELSEIF(${TYPE} STREQUAL "HD_VL")
        IF(STM32_SIZE_CODE STREQUAL "C")
            SET(RAM "24K")
        ELSE()
            SET(RAM "32K")
        ENDIF()
    ENDIF()
    
    SET(${RAM_SIZE} ${RAM})
ENDMACRO()
