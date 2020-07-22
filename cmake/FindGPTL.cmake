# FindGPTL.cmake
#
# Copyright UCAR 2020
#
# Find the GPTL: General Purpose Timing Library (https://jmrosinski.github.io/GPTL/)
#
# This find modules uses pkg-config to locate GPTL and glean the appropriate flags, directories, link dependencies.
#
# GPTL_FOUND - True if GPTL was found
# GPTL::GPTL - Imported interface target to pass to target_link_libraries()
# GPTL_VERSION_STRING - Version of installed GPTL
# GPTL_BIN_DIR - GPTL binary directory
# GPTL_HAS_PKG_CONFIG -  Found installed gptl.pc file -- pkg-config support enabled
#
#

find_package(PkgConfig QUIET)

#Helper:
#check_pkg_config(ret_var pcname pcflags...)
# Check if pcname is known to pkg-config
# Returns:
#  Boolean: true if ${pcname}.pc file is found by pkg-config).
# Args:
#  ret_var: return variable name.
#  pcname: pkg-config name to look for (.pc file)
function(check_pkg_config ret_var pcname)
    if(NOT PKG_CONFIG_FOUND OR NOT EXISTS ${PKG_CONFIG_EXECUTABLE})
        set(${ret_var} False PARENT_SCOPE)
    else()
        execute_process(COMMAND ${PKG_CONFIG_EXECUTABLE} --exists ${pcname} RESULT_VARIABLE _found)
        message(STATUS "FOUND: ${_found}")
        if(_found EQUAL 0)
            set(${ret_var} True PARENT_SCOPE)
        else()
            set(${ret_var} False PARENT_SCOPE)
        endif()
    endif()
endfunction()

#Helper:
#get_pkg_config(ret_var pcname pcflags...)
# Get the output of pkg-config
# Args:
#  ret_var: return variable name
#  pcname: pkg-config name to look for (.pc file)
#  pcflags: pkg-config flags to pass
function(get_pkg_config ret_var pcname pcflags)
    execute_process(COMMAND ${PKG_CONFIG_EXECUTABLE} ${ARGN} ${pcname} ${pcflags} OUTPUT_VARIABLE _out RESULT_VARIABLE _ret OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(_ret EQUAL 0)
        separate_arguments(_out)
        set(${ret_var} ${_out} PARENT_SCOPE)
    else()
        set(${ret_var} "" PARENT_SCOPE)
    endif()
endfunction()

#Attempt to use pkg-config to get as much information as possible
check_pkg_config(GPTL_HAS_PKG_CONFIG gptl)
if(GPTL_HAS_PKG_CONFIG)
    get_pkg_config(GPTL_VERSION_STRING gptl --modversion)
    get_pkg_config(GPTL_PREFIX gptl --variable=prefix)
    get_pkg_config(GPTL_INCLUDE_DIR gptl --cflags-only-I)
    if(GPTL_INCLUDE_DIR)
        string(REGEX REPLACE "-I([^ ]+)" "\\1;" GPTL_INCLUDE_DIR ${GPTL_INCLUDE_DIR}) #Remove -I
    endif()
    get_pkg_config(GPTL_COMPILE_OPTIONS gptl --cflags-only-other)
    get_pkg_config(GPTL_LINK_LIBRARIES gptl --libs-only-l)
    get_pkg_config(GPTL_LINK_DIRECTORIES gptl --libs-only-L)
    if(GPTL_LINK_DIRECTORIES)
        string(REGEX REPLACE "-L([^ ]+)" "\\1;" GPTL_LINK_DIRECTORIES ${GPTL_LINK_DIRECTORIES}) #Remove -L
    endif()
    get_pkg_config(GPTL_LINK_OPTIONS gptl --libs-only-other)
else()
    message(WARNING "GPTL: PkgConfig not found.  Unable to query compiler and linker options.  Attempting to find GPTL component paths individually.")
endif()
if(NOT GPTL_INCLUDE_DIR)
    find_path(GPTL_INCLUDE_DIR NAMES gptl.h PATHS ${GPTL_PREFIX_HINTS} PATH_SUFFIXES include include/gptl)
endif()
find_path(GPTL_MODULE_DIR NAMES gptl.mod PATHS ${GPTL_PREFIX_HINTS} PATH_SUFFIXES include include/gptl module module/gptl)
find_path(GPTL_BIN_DIR NAMES gptl_avail PATHS ${GPTL_PREFIX_HINTS} PATH_SUFFIXES bin)
find_library(GPTL_LIBRARY NAMES gptl PATHS ${GPTL_PREFIX_HINTS} PATH_SUFFIXES lib lib64)


#Check package has been found correctly
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
  GPTL
  REQUIRED_VARS
    GPTL_LIBRARY
    GPTL_INCLUDE_DIR
    GPTL_MODULE_DIR
    GPTL_BIN_DIR
  VERSION_VAR
    GPTL_VERSION_STRING
)

#Hide non-documented variables reserved for internal/advanced usage
mark_as_advanced(GPTL_VERSION_STRING
                 GPTL_PREFIX
                 GPTL_INCLUDE_DIR
                 GPTL_MODULE_DIR
                 GPTL_COMPILE_OPTIONS
                 GPTL_LIBRARY
                 GPTL_LINK_LIBRARIES
                 GPTL_LINK_DIRECTORIES
                 GPTL_LINK_OPTIONS)

#Debugging output
message(DEBUG "GPTL_FOUND: ${GPTL_FOUND}")
message(DEBUG "GPTL_VERSION_STRING: ${GPTL_VERSION_STRING}")
message(DEBUG "GPTL_PREFIX: ${GPTL_PREFIX}")
message(DEBUG "GPTL_BIN_DIR: ${GPTL_BIN_DIR}")
message(DEBUG "GPTL_INCLUDE_DIR: ${GPTL_INCLUDE_DIR}")
message(DEBUG "GPTL_MODULE_DIR: ${GPTL_MODULE_DIR}")
message(DEBUG "GPTL_LIBRARY: ${GPTL_LIBRARY}")
message(DEBUG "GPTL_LINK_LIBRARIES: ${GPTL_LINK_LIBRARIES}")
message(DEBUG "GPTL_LINK_DIRECTORIES: ${GPTL_LINK_DIRECTORIES}")
message(DEBUG "GPTL_LINK_OPTIONS: ${GPTL_LINK_OPTIONS}")

#Create GPTL::GPTL imported interface target
if(GPTL_FOUND AND NOT TARGET GPTL::GPTL)
    add_library(GPTL::GPTL INTERFACE IMPORTED)
    set_property(TARGET GPTL::GPTL PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${GPTL_INCLUDE_DIR})
    if(GPTL_MODULE_DIR)
        set_property(TARGET GPTL::GPTL APPEND PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${GPTL_MODULE_DIR})
    endif()
    if(GPTL_COMPILE_OPTIONS)
        set_property(TARGET GPTL::GPTL PROPERTY INTERFACE_COMPILE_OPTIONS ${GPTL_COMPILE_OPTIONS})
    endif()
    if(GPTL_LINK_DIRECTORIES)
        set_property(TARGET GPTL::GPTL PROPERTY INTERFACE_LINK_DIRECTORIES ${GPTL_LINK_DIRECTORIES})
    endif()
    if(GPTL_LINK_OPTIONS)
        set_property(TARGET GPTL::GPTL PROPERTY INTERFACE_LINK_OPTIONS ${GPTL_LINK_OPTIONS})
    endif()
    if(GPTL_LINK_LIBRARIES)
        set_property(TARGET GPTL::GPTL PROPERTY INTERFACE_LINK_LIBRARIES ${GPTL_LINK_LIBRARIES})
    else()
        set_property(TARGET GPTL::GPTL PROPERTY INTERFACE_LINK_LIBRARIES ${GPTL_LIBRARY})
        get_filename_component(_lib_dir ${GPTL_LIBRARY} DIRECTORY)
        set_property(TARGET GPTL::GPTL APPEND PROPERTY INTERFACE_LINK_DIRECTORIES ${_lib_dir})
        unset(_lib_dir)
    endif()
endif()
