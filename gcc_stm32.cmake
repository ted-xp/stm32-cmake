INCLUDE(CMakeForceCompiler)
INCLUDE(${CMAKE_CURRENT_LIST_DIR}/gcc_stm32_sizeutil.cmake)
INCLUDE(${CMAKE_CURRENT_LIST_DIR}/gcc_stm32_common.cmake)

SET(STM32_SUPPORTED_FAMILIES F0 F1 F2 F4 CACHE INTERNAL "stm32 supported families")

IF(NOT TOOLCHAIN_PREFIX)
     SET(TOOLCHAIN_PREFIX "/usr")
     MESSAGE(STATUS "No TOOLCHAIN_PREFIX specified, using default: " ${TOOLCHAIN_PREFIX})
ENDIF()

IF(NOT TARGET_TRIPLET)
    SET(TARGET_TRIPLET "arm-none-eabi")
    MESSAGE(STATUS "No TARGET_TRIPLET specified, using default: " ${TARGET_TRIPLET})
ENDIF()

IF(NOT STM32_FAMILY)
    MESSAGE(STATUS "No STM32_FAMILY specified, trying to get it from STM32_CHIP")
    IF(NOT STM32_CHIP)
        SET(STM32_FAMILY "F1" CACHE INTERNAL "stm32 family")
        MESSAGE(STATUS "Neither STM32_FAMILY nor STM32_CHIP specified, using default STM32_FAMILY: ${STM32_FAMILY}")
    ELSE()
        STRING(REGEX REPLACE "^[sS][tT][mM]32(([fF][0-4])|([lL][0-1])|([tT])|([wW])).+$" "\\1" STM32_FAMILY ${STM32_CHIP})
        STRING(TOUPPER ${STM32_FAMILY} STM32_FAMILY)
        MESSAGE(STATUS "Selected STM32 family: ${STM32_FAMILY}")
    ENDIF()
ENDIF()

STRING(TOUPPER ${STM32_FAMILY} STM32_FAMILY)
LIST(FIND STM32_SUPPORTED_FAMILIES ${STM32_FAMILY} FAMILY_INDEX)
IF(FAMILY_INDEX EQUAL -1)
    MESSAGE(FATAL_ERROR "Invalid/unsupported STM32 family: ${STM32_FAMILY}")
ENDIF()

SET(TOOLCHAIN_BIN_DIR ${TOOLCHAIN_PREFIX}/bin)
SET(TOOLCHAIN_INC_DIR ${TOOLCHAIN_PREFIX}/${TARGET_TRIPLET}/include)
SET(TOOLCHAIN_LIB_DIR ${TOOLCHAIN_PREFIX}/${TARGET_TRIPLET}/lib)

SET(CMAKE_SYSTEM_NAME Generic)
SET(CMAKE_SYSTEM_PROCESSOR arm)

MACRO (SETUP_BUILD_TOOL var name)
   FIND_PROGRAM(CMAKE_${var} ${TARGET_TRIPLET}-${name} HINTS ${TOOLCHAIN_BIN_DIR} DOC "${name} tool")
ENDMACRO()

IF(NOT CMAKE_C_COMPILER)
   SETUP_BUILD_TOOL(C_COMPILER gcc)
   IF(CMAKE_C_COMPILER)
      CMAKE_FORCE_C_COMPILER(${CMAKE_C_COMPILER} GNU)
      MESSAGE(STATUS "Force GNU C compiler: ${CMAKE_C_COMPILER}")
   ENDIF()
ENDIF()

IF(NOT CMAKE_CXX_COMPILER)
   SETUP_BUILD_TOOL(CXX_COMPILER g++)
   IF(CMAKE_CXX_COMPILER)
      CMAKE_FORCE_CXX_COMPILER(${CMAKE_CXX_COMPILER} GNU)
      MESSAGE(STATUS "Force GNU C++ compiler: ${CMAKE_CXX_COMPILER}")
   ENDIF()
ENDIF()

SETUP_BUILD_TOOL(ASM-ATT_COMPILER as)

SET(CMAKE_OBJCOPY ${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLET}-objcopy CACHE INTERNAL "objcopy tool")
SET(CMAKE_OBJDUMP ${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLET}-objdump CACHE INTERNAL "objdump tool")

STRING(TOLOWER ${STM32_FAMILY} STM32_FAMILY_LOWER)
INCLUDE(${CMAKE_CURRENT_LIST_DIR}/gcc_stm32${STM32_FAMILY_LOWER}.cmake)

# --------------------------

SET(STM32_CMAKE_XXX_COMPILER_FLAGS "${STM32_CMAKE_XXX_COMPILER_FLAGS} -g") # always include debug information
SET(STM32_CMAKE_CXX_COMPILER_FLAGS "${STM32_CMAKE_CXX_COMPILER_FLAGS} -fvisibility=hidden -fno-builtin -Wall -ffunction-sections -fdata-sections -fomit-frame-pointer -mabi=aapcs -fno-unroll-loops -ffast-math -ftree-vectorize")
SET(STM32_CMAKE_CXX_COMPILER_FLAGS "${STM32_CMAKE_XXX_COMPILER_FLAGS} ${STM32_CMAKE_CXX_COMPILER_FLAGS} ${STM32_BOARD_DEFINITIONS}")
SET(STM32_CMAKE_ASM_COMPILER_FLAGS "${STM32_CMAKE_XXX_COMPILER_FLAGS} ${STM32_CMAKE_ASM_COMPILER_FLAGS}")
SET(STM32_CMAKE_XXX_LINKER_FLAGS   "${STM32_CMAKE_XXX_LINKER_FLAGS} -mabi=aapcs")

SET(STM32_CMAKE_C_COMPILER_FLAGS_RELEASE "-DNDEBUG -Os -flto -fuse-linker-plugin -ffat-lto-objects")
SET(STM32_CMAKE_CXX_COMPILER_FLAGS_RELEASE "${STM32_CMAKE_C_COMPILER_FLAGS_RELEASE} -finline-functions -frename-registers")
SET(STM32_CMAKE_LINKER_FLAGS_RELEASE "-flto")

SET(CMAKE_C_FLAGS "-std=gnu99 ${STM32_CMAKE_CXX_COMPILER_FLAGS}" CACHE INTERNAL "c compiler flags")
SET(CMAKE_CXX_FLAGS "-std=c++11 ${STM32_CMAKE_CXX_COMPILER_FLAGS}" CACHE INTERNAL "cxx compiler flags")
SET(CMAKE_ASM_FLAGS "${STM32_CMAKE_ASM_COMPILER_FLAGS}" CACHE INTERNAL "cxx compiler flags")

SET(CMAKE_C_FLAGS_DEBUG "-O0 -g" CACHE INTERNAL "c compiler flags debug")
SET(CMAKE_CXX_FLAGS_DEBUG "-O0 -g" CACHE INTERNAL "cxx compiler flags debug")
SET(CMAKE_ASM_FLAGS_DEBUG "-g" CACHE INTERNAL "asm compiler flags debug")
SET(CMAKE_EXE_LINKER_FLAGS_DEBUG "" CACHE INTERNAL "linker flags debug")

SET(CMAKE_C_FLAGS_RELEASE "${STM32_CMAKE_C_COMPILER_FLAGS_RELEASE}" CACHE INTERNAL "c compiler flags release")
SET(CMAKE_CXX_FLAGS_RELEASE "${STM32_CMAKE_CXX_COMPILER_FLAGS_RELEASE}" CACHE INTERNAL "cxx compiler flags release")
SET(CMAKE_ASM_FLAGS_RELEASE "" CACHE INTERNAL "asm compiler flags release")
SET(CMAKE_EXE_LINKER_FLAGS_RELEASE "${STM32_CMAKE_LINKER_FLAGS_RELEASE}" CACHE INTERNAL "linker flags release")

SET(CMAKE_C_FLAGS_RELWITHDEBINFO "${STM32_CMAKE_C_COMPILER_FLAGS_RELEASE}" CACHE INTERNAL "c compiler flags release")
SET(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${STM32_CMAKE_CXX_COMPILER_FLAGS_RELEASE}" CACHE INTERNAL "cxx compiler flags release")
SET(CMAKE_ASM_FLAGS_RELWITHDEBINFO "" CACHE INTERNAL "asm compiler flags release")
SET(CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO "${STM32_CMAKE_LINKER_FLAGS_RELEASE}" CACHE INTERNAL "linker flags release")

SET(CMAKE_EXE_LINKER_FLAGS "-Wl,--gc-sections ${STM32_CMAKE_XXX_LINKER_FLAGS}" CACHE INTERNAL "executable linker flags")
SET(CMAKE_MODULE_LINKER_FLAGS "${STM32_CMAKE_XXX_LINKER_FLAGS}" CACHE INTERNAL "module linker flags")
SET(CMAKE_SHARED_LINKER_FLAGS "${STM32_CMAKE_XXX_LINKER_FLAGS}" CACHE INTERNAL "shared linker flags")

# --------------------------

SET(CMAKE_FIND_ROOT_PATH ${TOOLCHAIN_PREFIX}/${TARGET_TRIPLET} ${EXTRA_FIND_PATH})
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

FUNCTION(STM32_ADD_HEX_BIN_TARGETS TARGET)
    IF(EXECUTABLE_OUTPUT_PATH)
      SET(FILENAME "${EXECUTABLE_OUTPUT_PATH}/${TARGET}")
    ELSE()
      SET(FILENAME "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}")
    ENDIF()
    ADD_CUSTOM_TARGET(${TARGET}.hex DEPENDS ${TARGET} COMMAND ${CMAKE_OBJCOPY} -Oihex ${FILENAME} ${FILENAME}.hex)
    ADD_CUSTOM_TARGET(${TARGET}.bin DEPENDS ${TARGET} COMMAND ${CMAKE_OBJCOPY} -Obinary ${FILENAME} ${FILENAME}.bin)
ENDFUNCTION()

FUNCTION(STM32_CALL_SET_FLASH_PARAMS)
    SET(r "")
    FOREACH(I ${STM32_LINKER_SCRIPT})
        MESSAGE(STATUS "Processing linker file ${I}")
        GET_FILENAME_COMPONENT(name ${I} NAME_WE)
        SET(name ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_${name}.ld)
        CONFIGURE_FILE(${I} ${name})
        LIST(APPEND r ${name})
    ENDFOREACH()
    LIST(GET r 0 name)
    SET_TARGET_PROPERTIES(${TARGET} PROPERTIES LINK_FLAGS "-T${name} ${CMAKE_EXE_LINKER_FLAGS}")
ENDFUNCTION()

FUNCTION(STM32_SET_FLASH_PARAMS TARGET STM32_FLASH_SIZE STM32_RAM_SIZE STM32_STACK_ADDRESS STM32_MIN_STACK_SIZE STM32_MIN_HEAP_SIZE STM32_FLASH_ORIGIN STM32_RAM_ORIGIN)
    IF(NOT STM32_LINKER_SCRIPT)
        MESSAGE(FATAL_ERROR "No linker script specified. Please specify linker script using STM32_LINKER_SCRIPT variable.")
    ENDIF()
    STM32_CALL_SET_FLASH_PARAMS()
ENDFUNCTION()

FUNCTION(STM32_SET_FLASH_PARAMS TARGET FLASH_SIZE RAM_SIZE)
    IF(NOT STM32_LINKER_SCRIPT)
        MESSAGE(FATAL_ERROR "No linker script specified. Please specify linker script using STM32_LINKER_SCRIPT variable.")
    ENDIF()

    IF(NOT STM32_FLASH_ORIGIN)
        SET(STM32_FLASH_ORIGIN "0x08000000")
    ENDIF() 
    
    IF(NOT STM32_RAM_ORIGIN)
        SET(STM32_RAM_ORIGIN "0x20000000")
    ENDIF()
    
    STM32_MEMSIZE_TO_HEX_BYTES(${FLASH_SIZE} STM32_FLASH_SIZE)
    STM32_MEMSIZE_TO_HEX_BYTES(${RAM_SIZE} STM32_RAM_SIZE)
    
    IF(NOT STM32_MIN_STACK_SIZE)
        SET(STM32_MIN_STACK_SIZE "0x200")
    ENDIF()
    
    IF(NOT STM32_MIN_HEAP_SIZE)
        SET(STM32_MIN_HEAP_SIZE "0x0")
    ENDIF()
    
    IF(NOT EXT_RAM_SIZE)
       SET(EXT_RAM_SIZE "0")
    ENDIF()

    IF(NOT EXT_RAM_ORIGIN)
       SET(EXT_RAM_ORIGIN "0")
    ENDIF()
 
    STM32_CALL_SET_FLASH_PARAMS()
ENDFUNCTION()

FUNCTION(STM32_SET_LIBTARGET_PROPERTIES TARGET)
    IF(NOT STM32_CHIP_TYPE)
        IF(NOT STM32_CHIP)
            MESSAGE(WARNING "Neither STM32_CHIP_TYPE nor STM32_CHIP selected, you'll have to use STM32_SET_CHIP_DEFINITIONS directly")
        ELSE()
            STM32_GET_CHIP_TYPE(${STM32_CHIP} STM32_CHIP_TYPE)
        ENDIF() 
    ENDIF()
    STM32_SET_CHIP_DEFINITIONS(${TARGET} ${STM32_CHIP_TYPE})
ENDFUNCTION()

FUNCTION(STM32_SET_TARGET_PROPERTIES TARGET)
    STM32_SET_LIBTARGET_PROPERTIES(${TARGET})
    IF(((NOT STM32_FLASH_SIZE) OR (NOT STM32_RAM_SIZE)) AND (NOT STM32_CHIP))
        MESSAGE(FATAL_ERROR "Cannot get chip parameters. Please specify either STM32_CHIP or STM32_FLASH_SIZE/STM32_RAM_SIZE")
    ENDIF()
    IF((NOT STM32_FLASH_SIZE) OR (NOT STM32_RAM_SIZE))
        STM32_GET_CHIP_PARAMETERS(${STM32_CHIP} STM32_FLASH_SIZE STM32_RAM_SIZE)
        IF((NOT STM32_FLASH_SIZE) OR (NOT STM32_RAM_SIZE))
            MESSAGE(FATAL_ERROR "Unknown chip: ${STM32_CHIP}. Try to use STM32_FLASH_SIZE/STM32_RAM_SIZE directly.")
        ENDIF()
    ENDIF()
    STM32_SET_FLASH_PARAMS(${TARGET} ${STM32_FLASH_SIZE} ${STM32_RAM_SIZE})
    MESSAGE(STATUS "${STM32_CHIP} has ${STM32_FLASH_SIZE}iB of flash memory and ${STM32_RAM_SIZE}iB of RAM")
ENDFUNCTION()

FUNCTION(STM32_GET_SELECTED_CHIP_TYPES out)
   IF(STM32_CHIP)
      STM32_GET_CHIP_TYPE(${STM32_CHIP} tmp)
      SET(${out} "${tmp}" PARENT_SCOPE)
   ELSE()
      SET(${out} "${STM32_CHIP_TYPES}" PARENT_SCOPE)
   ENDIF()
ENDFUNCTION()

MACRO(STM32_GENERATE_LIBRARIES NAME SOURCES LIBRARIES)
    STRING(TOLOWER ${STM32_FAMILY} STM32_FAMILY_LOWER)
    FOREACH(CHIP_TYPE ${STM32_CHIP_TYPES})
        STRING(TOLOWER ${CHIP_TYPE} CHIP_TYPE_LOWER)
        LIST(APPEND ${LIBRARIES} ${NAME}_${STM32_FAMILY_LOWER}_${CHIP_TYPE_LOWER})
        ADD_LIBRARY(${NAME}_${STM32_FAMILY_LOWER}_${CHIP_TYPE_LOWER} ${SOURCES})
        STM32_SET_CHIP_DEFINITIONS(${NAME}_${STM32_FAMILY_LOWER}_${CHIP_TYPE_LOWER} ${CHIP_TYPE})
    ENDFOREACH()
ENDMACRO()

FUNCTION(STM32_GENERATE_MAP TARGET)
   # TODO: Invent how to place map file in the same folder as binary file ($<TARGET_NAME> is prohibited here :( )
   TARGET_LINK_LIBRARIES(${TARGET} "-Wl,-Map=$<TARGET_PROPERTY:NAME>.map")
   SET_PROPERTY(DIRECTORY APPEND_STRING PROPERTY ADDITIONAL_MAKE_CLEAN_FILES "$<TARGET_PROPERTY:NAME>.map")
ENDFUNCTION()

FUNCTION(STM32_ADD_LINKER_SPEC TARGET) # ...
    FOREACH(I ${ARGN})
        SET_PROPERTY(TARGET ${TARGET} APPEND_STRING PROPERTY LINK_FLAGS " --specs=${I}")
    ENDFOREACH()
ENDFUNCTION()
