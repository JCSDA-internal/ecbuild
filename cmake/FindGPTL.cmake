# FindGPTL.cmake
#
# Copyright UCAR 2020



#Helper:
#check_pkg_config(ret_var pcname pcflags...)
# Check if pcname is known to pkg-config
# Returns:
#  Boolean: true if ${pcname}.pc file is found by pkg-config).
# Args:
#  ret_var: return variable name.
#  pcname: pkg-config name to look for (.pc file)
function(check_pkg_config ret_var pcname)
    execute_process(COMMAND ${PKG_CONFIG_EXECUTABLE} --exists ${pcname} RESULT_VARIABLE _found)
    if(_found EQUAL 0)
        set(${ret_var} True PARENT_SCOPE)
    else()
        set(${ret_var} False PARENT_SCOPE)
    endif()
endfunction()

#Helper:
#get_pkg_config(ret_var pcname pcflags...)
# Get the output of pkg-config
# Args:
#  ret_var: return variable name
#  pcname: pkg-config name to look for (.pc file)
#  pcflags: pkg-config flags to pass
function(get_pkg_config ret_var pcname)
    execute_process(COMMAND ${PKG_CONFIG_EXECUTABLE} ${ARGN} ${pcname} OUTPUT_VARIABLE _out RESULT_VARIABLE _ret OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(_ret EQUAL 0)
        separate_arguments(_out)
        set(${ret_var} ${_out} PARENT_SCOPE)
    else()
        set(${ret_var} "" PARENT_SCOPE)
    endif()
endfunction()

find_path(TRNG_INCLUDE_DIR NAMES trng/lcg64.hpp PATHS ${TRNG_PREFIX_HINTS} PATH_SUFFIXES include)
find_library(TRNG_LIBRARY NAMES trng4 PATHS ${TRNG_PREFIX_HINTS} PATH_SUFFIXES lib lib64)

if(TRNG_INCLUDE_DIR)
    file(READ ${TRNG_INCLUDE_DIR}/trng/config.hpp TRNG_CONFIG)
    set(TRNG_VER_REGEX "TRNG_VERSION [0-9]+\\.[0-9]+")
    string(REGEX MATCH ${TRNG_VER_REGEX} TRNG_VER_SUBSTR ${TRNG_CONFIG})
    string(SUBSTRING ${TRNG_VER_SUBSTR} 13 -1 TRNG_VERSION_STRING)
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
  TRNG
  REQUIRED_VARS
    TRNG_LIBRARY
    TRNG_INCLUDE_DIR
  VERSION_VAR
    TRNG_VERSION_STRING
)

mark_as_advanced(TRNG_INCLUDE_DIR
                 TRNG_LIBRARY
                 TRNG_VERSION_STRING)

if(TRNG_FOUND AND NOT TARGET TRNG::TRNG)
    get_filename_component(_lib_dir ${TRNG_LIBRARY} DIRECTORY)
    add_library(TRNG::TRNG INTERFACE IMPORTED)
    set_target_properties(TRNG::TRNG PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES ${TRNG_INCLUDE_DIR}
        INTERFACE_LINK_LIBRARIES ${TRNG_LIBRARY})
    unset(_lib_dir)
endif()
