INCLUDE(${CMAKE_CURRENT_LIST_DIR}/LocateSTMUtil.cmake)

STRING(TOLOWER ${STM32_FAMILY} STM32_FAMILY_LOWER)

STM32_LOCATE_CMSIS_REL_HEADERS()
STM32_SET_FILE_NAMES(CMSIS_HEADERS ${STM32_CMSIS_REL_HEADERS_${STM32_FAMILY}})

IF(STM32_FAMILY STREQUAL "F0")
    SET(CMSIS_STARTUP_PREFIX startup_stm32f)
ELSEIF(STM32_FAMILY STREQUAL "F1")
    SET(CMSIS_STARTUP_PREFIX startup_stm32f10x_)
ELSEIF(STM32_FAMILY STREQUAL "F2")
    SET(CMSIS_STARTUP_PREFIX startup_stm32f)
ELSEIF(STM32_FAMILY STREQUAL "F4")
    SET(CMSIS_STARTUP_PREFIX startup_stm32f)
ENDIF()

SET(CMSIS_LINKER_SCRIPT_NAME
    stm32fx_flash.ld.in
    stm32${STM32_FAMILY_LOWER}_memory.ld.in
    stm32${STM32_FAMILY_LOWER}_sections.ld.in
)

IF((NOT STM32_CHIP_TYPE) AND (NOT STM32_CHIP))
    UNSET(CMSIS_STARTUP_NAME)
    UNSET(CMSIS_STARTUP_SOURCE)
    FOREACH(CHIP_TYPE ${STM32_CHIP_TYPES})
        STRING(TOLOWER ${CHIP_TYPE} CHIP_TYPE_LOWER)
        LIST(APPEND CMSIS_FIND_LIBS cmsis_${STM32_FAMILY_LOWER}_${CHIP_TYPE_LOWER})
    ENDFOREACH()    
ELSE()
    IF(NOT STM32_CHIP_TYPE)
        STM32_GET_CHIP_TYPE(${STM32_CHIP} STM32_CHIP_TYPE)
        IF(NOT STM32_CHIP_TYPE)
            MESSAGE(FATAL_ERROR "Unknown chip: ${STM32_CHIP}. Try to use STM32_CHIP_TYPE directly.")
        ENDIF()
        MESSAGE(STATUS "${STM32_CHIP} is ${STM32_CHIP_TYPE} device")
    ENDIF()
    STRING(TOLOWER ${STM32_CHIP_TYPE} STM32_CHIP_TYPE_LOWER)
    
    SET(CMSIS_FIND_LIBS cmsis_${STM32_FAMILY_LOWER}_${STM32_CHIP_TYPE_LOWER})
    SET(CMSIS_STARTUP_NAME ${CMSIS_STARTUP_PREFIX}${STM32_CHIP_TYPE_LOWER}.s)
ENDIF()

FIND_PATH(CMSIS_INCLUDE_DIR
    ${CMSIS_HEADERS}
    PATH_SUFFIXES include stm32${STM32_FAMILY_LOWER}
)

FOREACH(CMSIS_LIB_NAME ${CMSIS_FIND_LIBS})
    SET(CMSIS_LIBRARY CMSIS_LIBRARY-NOTFOUND)
    FIND_LIBRARY(CMSIS_LIBRARY
        NAMES ${CMSIS_LIB_NAME}
        PATH_SUFFIXES lib
    )
    LIST(APPEND CMSIS_LIBRARIES ${CMSIS_LIBRARY})
ENDFOREACH()
SET(CMSIS_FORCE_SBRK_OVERRIDE "-Wl,--undefined=_sbrk")
LIST(APPEND CMSIS_LIBRARIES "${CMSIS_FORCE_SBRK_OVERRIDE}")

# Locating script file full path and name
SET(CMSIS_LINKER_SCRIPT "")
FOREACH(I ${CMSIS_LINKER_SCRIPT_NAME})
    FIND_FILE(CMSIS_LINKER_SCRIPT_ITEM_${I}
        ${I}
        PATHS ${CMAKE_FIND_ROOT_PATH}
        PATH_SUFFIXES share/cmsis
        NO_CMAKE_FIND_ROOT_PATH
    )
    LIST(APPEND CMSIS_LINKER_SCRIPT ${CMSIS_LINKER_SCRIPT_ITEM_${I}})
ENDFOREACH()

INCLUDE(FindPackageHandleStandardArgs)
IF(NOT STM32_CHIP_TYPE)
    FIND_PACKAGE_HANDLE_STANDARD_ARGS(CMSIS DEFAULT_MSG CMSIS_LIBRARIES CMSIS_INCLUDE_DIR CMSIS_LINKER_SCRIPT) 
ELSE()
    FIND_FILE(CMSIS_STARTUP_SOURCE
        ${CMSIS_STARTUP_NAME}
        PATHS ${CMAKE_FIND_ROOT_PATH}
        PATH_SUFFIXES share/cmsis
        NO_CMAKE_FIND_ROOT_PATH
    )
    FIND_PACKAGE_HANDLE_STANDARD_ARGS(CMSIS DEFAULT_MSG CMSIS_LIBRARIES CMSIS_INCLUDE_DIR CMSIS_STARTUP_SOURCE CMSIS_LINKER_SCRIPT) 
ENDIF()
