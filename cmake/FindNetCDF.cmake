# (C) Copyright 2011- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation nor
# does it submit to any jurisdiction.

# Try to find NetCDF includes and library.  
# Supports static and shared libaries and allows each component to be found in sepearte prefixes.
#
# This module defines
#
#   - NetCDF_FOUND                - System has NetCDF
#   - NetCDF_INCLUDE_DIRS         - the NetCDF include directories
#   - NetCDF_VERSION              - the version of NetCDF
#   - NetCDF_CONFIG_EXECUTABLE    - the netcdf-config executable if found
#   - NetCDF_PARALLEL             - Boolean True if NetCDF4 has parallel IO support via hdf5 and/or pnetcdf
#   - NetCDF_HAS_PNETCDF          - Boolean True if NetCDF4 has pnetcdf support

#
# Following components are available:
#
#   - C                           - C interface to NetCDF          (netcdf)
#   - CXX                         - CXX4 interface to NetCDF       (netcdf_c++4)
#   - Fortran                     - Fortran interface to NetCDF    (netcdff)
#   - CXX_LEGACY                  - Legacy C++ interface to NetCDF (netcdf_c++)
#
# For each component the following are defined:
#
#   - NetCDF_<comp>_FOUND         - whether the component is found
#   - NetCDF_<comp>_LIBRARIES     - the libraries for the component
#   - NetCDF_<comp>_LIBRARY_STATIC - Boolean is true if libraries for component are static
#   - NetCDF_<comp>_LIBRARY_SHARED - Boolean is true if libraries for component are shared
#   - NetCDF_<comp>_INCLUDE_DIRS  - the include directories for specfied component
#   - NetCDF::NetCDF_<comp>       - target of component to be used with target_link_libraries()
#
# The following paths will be searched in order if set in CMake (first priority) or environment (second priority)
#
#   - NetCDF_ROOT                 - root of NetCDF installation
#   - NetCDF_PATH                 - root of NetCDF installation
#
# The search process begins with locating NetCDF Include headers.  If these are in a non-standard location,
# set one of the following CMake or environment variables to point to the location:
#
#  - NetCDF_INCLUDE_DIR or NetCDF_${comp}_INCLUDE_DIR
#  - NetCDF_INCLUDE_DIRS or NetCDF_${comp}_INCLUDE_DIR
#
# Notes:
#
#   - Each variable is also available in fully uppercased version
#   - Preferred naming for this package and it's variables is "NetCDF"
#     For compatability, each variable not in targets, can subsititue "NetCDF" with
#        * NetCDF4
#        * NETCDF
#        * NETCDF4
#   - Preferred component capitalisation follows the CMake LANGUAGES variables.
#     For compatability, capitalisation of COMPONENT arguments does not matter.
#     The <comp> part of variables will be defined with:
#        * capitalisation as defined above
#        * Uppercase capitalisation
#        * capitalisation as used in find_package() arguments
#   - If no components are defined, all components will be searched without guarantee that the 
#     required component is available.
#

list( APPEND _possible_components C CXX Fortran CXX_LEGACY )

## Include names for each component
set( NetCDF_C_INCLUDE_NAME          netcdf.h )
set( NetCDF_CXX_INCLUDE_NAME        netcdf )
set( NetCDF_Fortran_INCLUDE_NAME    netcdf.mod )

## Library names for each component
set( NetCDF_C_LIBRARY_NAME          netcdf )
set( NetCDF_CXX_LIBRARY_NAME        netcdf_c++4 )
set( NetCDF_CXX_LEGACY_LIBRARY_NAME netcdf_c++ )
set( NetCDF_Fortran_LIBRARY_NAME    netcdff )

## Enumerate search components
foreach( _comp ${_possible_components} )
  string( TOUPPER "${_comp}" _COMP )
  set( _arg_${_COMP} ${_comp} )
  set( _name_${_COMP} ${_comp} )
endforeach()

unset( _search_components )
foreach( _comp ${${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS} )
  string( TOUPPER "${_comp}" _COMP )
  set( _arg_${_COMP} ${_comp} )
  list( APPEND _search_components ${_name_${_COMP}} )
  if( NOT _name_${_COMP} )
    ecbuild_error( "Find${CMAKE_FIND_PACKAGE_NAME}: COMPONENT ${_comp} is not a valid component. Valid components: ${_possible_components}" )
  endif()
endforeach()
if( NOT _search_components )
  set( _search_components C Fortran )
endif()

## Search hints for finding include directories and libraries
foreach( _comp IN ITEMS "_" "_C_" "_Fortran_" "_CXX_" )
  foreach( _name IN ITEMS NetCDF4 NetCDF NETCDF4 NETCDF4 )
    foreach( _var IN ITEMS ROOT PATH )
      list(APPEND _search_hints ${${_name}${_comp}${_var}} $ENV{${_name}${_comp}${_var}} )
      list(APPEND _include_search_hints 
                ${${_name}${_comp}INCLUDE_DIR} $ENV{${_name}${_comp}INCLUDE_DIR}} 
                ${${_name}${_comp}INCLUDE_DIRS} $ENV{${_name}${_comp}INCLUDE_DIRS}} )
    endforeach()
  endforeach()
endforeach()

## Find headers for each component
set(NetCDF_INCLUDE_DIRS)
foreach( _comp IN LISTS _search_components )
  find_file(NetCDF_${_comp}_INCLUDE_FILE
    NAMES ${NetCDF_${_comp}_INCLUDE_NAME}
    DOC "NetCDF ${_comp} include directory"
    HINTS ${_include_search_hints} ${_search_hints}
    PATH_SUFFIXES include include/netcdf
  )
  mark_as_advanced(NetCDF_${_comp}_INCLUDE_FILE)
  ecbuild_debug("NetCDF_${_comp}_INCLUDE_FILE: ${NetCDF_${_comp}_INCLUDE_FILE}")
  if( NetCDF_${_comp}_INCLUDE_FILE )
    get_filename_component(NetCDF_${_comp}_INCLUDE_FILE ${NetCDF_${_comp}_INCLUDE_FILE} ABSOLUTE)
    get_filename_component(NetCDF_${_comp}_INCLUDE_DIR ${NetCDF_${_comp}_INCLUDE_FILE} DIRECTORY)
    list(APPEND NetCDF_INCLUDE_DIRS ${NetCDF_${_comp}_INCLUDE_DIR})
  endif()
endforeach()
list(REMOVE_DUPLICATES NetCDF_INCLUDE_DIRS)
set(NetCDF_INCLUDE_DIRS "${NetCDF_INCLUDE_DIRS}" CACHE STRING "NetCDF Include directory paths" FORCE)

## Find nc-config executable
find_program( NetCDF_CONFIG_EXECUTABLE
    NAMES nc-config
    HINTS ${NetCDF_INCLUDE_DIRS} ${_include_search_hints} ${_search_hints}
    PATH_SUFFIXES bin Bin ../bin ../../bin
    DOC "NetCDF nc-config helper" )
ecbuild_debug("NetCDF_CONFIG_EXECUTABLE:${NetCDF_CONFIG_EXECUTABLE}")

set(_C_nclibs_flag --libs)
set(_Fortran_nclibs_flag --flibs)
set(_CXX_nclibs_flag --cxx4libs)
set(_C_ncflags_flag --cflags)
set(_Fortran_ncflags_flag --fflags)
set(_CXX_ncflags_flag --cxx4flags)
function(nc_config flag output_var)
  set(${output_var} False PARENT_SCOPE)
  if( NetCDF_CONFIG_EXECUTABLE )
    execute_process( COMMAND ${NetCDF_CONFIG_EXECUTABLE} ${flag} RESULT_VARIABLE _ret OUTPUT_VARIABLE _val)
    if( _ret EQUAL 0 )
      string( STRIP ${_val} _val )
      set( ${output_var} ${_val} PARENT_SCOPE )
    endif()
  endif()
endfunction()

## Find libraries for each component
set( NetCDF_LIBRARIES )
foreach( _comp IN LISTS _search_components )
  string( TOUPPER "${_comp}" _COMP )

  find_library( NetCDF_${_comp}_LIBRARY
    NAMES ${NetCDF_${_comp}_LIBRARY_NAME}
    DOC "NetCDF ${_comp} library"
    HINTS ${NetCDF_${_comp}_INCLUDE_DIRS} ${_search_hints}
    PATH_SUFFIXES lib64 lib ../lib64 ../lib ../../lib64 ../../lib )
  mark_as_advanced( NetCDF_${_comp}_LIBRARY )
  get_filename_component(NetCDF_${_comp}_LIBRARY ${NetCDF_${_comp}_LIBRARY} ABSOLUTE)
  set(NetCDF_${_comp}_LIBRARY ${NetCDF_${_comp}_LIBRARY} CACHE STRING "NetCDF ${_comp} library" FORCE)
  ecbuild_debug("NetCDF_${_comp}_LIBRARY: ${NetCDF_${_comp}_LIBRARY}")


  if( NetCDF_${_comp}_LIBRARY )
    if( NetCDF_${_comp}_LIBRARY MATCHES ".a$" )
      set( NetCDF_${_comp}_LIBRARY_STATIC TRUE )
      set( NetCDF_${_comp}_LIBRARY_SHARED FALSE )
      set( _library_type STATIC)
    else()
      set( NetCDF_${_comp}_LIBRARY_STATIC FALSE )
      set( NetCDF_${_comp}_LIBRARY_SHARED TRUE )
      set( _library_type SHARED)
    endif()
  endif()
  
  #Use nc-config to set per-component LIBRARIES variable if possible
  nc_config( ${_${_comp}_nclibs_flag} _val )
  if( _val )
    set( NetCDF_${_comp}_LIBRARIES ${_val} )
  else()
    set( NetCDF_${_comp}_LIBRARIES ${NetCDF_${_comp}_LIBRARY} )
  endif()
  
  #Use nc-config to set per-component INCLUDE_DIRS variable if possible
  nc_config( ${_${_comp}_ncflags_flag} _val )
  if( _val )
    list(TRANSFORM _val REPLACE "-I" "")
    set( NetCDF_${_comp}_INCLUDE_DIRS ${_val} )
  else()
    set( NetCDF_${_comp}_INCLUDE_DIRS ${NetCDF_${_comp}_INCLUDE_DIR} )
  endif()

  if( NetCDF_${_comp}_LIBRARIES AND NetCDF_${_comp}_INCLUDE_DIRS )
    set( ${CMAKE_FIND_PACKAGE_NAME}_${_arg_${_COMP}}_FOUND TRUE )
    if (NOT TARGET NetCDF::NetCDF_${_comp})
      add_library(NetCDF::NetCDF_${_comp} ${_library_type} IMPORTED)
      set_target_properties(NetCDF::NetCDF_${_comp} PROPERTIES
        IMPORTED_LOCATION ${NetCDF_${_comp}_LIBRARY}
        INTERFACE_INCLUDE_DIRECTORIES ${NetCDF_${_comp}_INCLUDE_DIRS}
        INTERFACE_LINK_LIBRARIES ${NetCDF_${_comp}_LIBRARIES} )
    endif()
    list( APPEND NetCDF_LIBRARIES NetCDF::NetCDF_${_comp} )
  endif()
endforeach()
set(NetCDF_LIBRARIES "${NetCDF_LIBRARIES}" CACHE STRING "NetCDF library targets" FORCE)

## Find version via netcdf-config if possible
if (NetCDF_INCLUDE_DIRS)
  if( NetCDF_CONFIG_EXECUTABLE )
    nc_config(--version _vers)
    if( _vers )
      string(REGEX REPLACE ".* ((([0-9]+)\\.)+([0-9]+)).*" "\\1" NetCDF_VERSION "${_vers}" )
    endif()
  else()
    foreach( _dir IN LISTS NetCDF_INCLUDE_DIRS)
      if( EXISTS "${_dir}/netcdf_meta.h" )
        file(STRINGS "${_dir}/netcdf_meta.h" _netcdf_version_lines
        REGEX "#define[ \t]+NC_VERSION_(MAJOR|MINOR|PATCH|NOTE)")
        string(REGEX REPLACE ".*NC_VERSION_MAJOR *\([0-9]*\).*" "\\1" _netcdf_version_major "${_netcdf_version_lines}")
        string(REGEX REPLACE ".*NC_VERSION_MINOR *\([0-9]*\).*" "\\1" _netcdf_version_minor "${_netcdf_version_lines}")
        string(REGEX REPLACE ".*NC_VERSION_PATCH *\([0-9]*\).*" "\\1" _netcdf_version_patch "${_netcdf_version_lines}")
        string(REGEX REPLACE ".*NC_VERSION_NOTE *\"\([^\"]*\)\".*" "\\1" _netcdf_version_note "${_netcdf_version_lines}")
        set(NetCDF_VERSION "${_netcdf_version_major}.${_netcdf_version_minor}.${_netcdf_version_patch}${_netcdf_version_note}")
        unset(_netcdf_version_major)
        unset(_netcdf_version_minor)
        unset(_netcdf_version_patch)
        unset(_netcdf_version_note)
        unset(_netcdf_version_lines)
      endif()
    endforeach()
  endif()
endif ()

## Detect additional package properties
nc_config(--has-parallel4 _val)
if( NOT _val )
    nc_config(--has-parallel _val)
endif()
set(NetCDF_PARALLEL ${_val} CACHE STRING "NetCDF has parallel IO capability via pnetcdf or hdf5." FORCE)

## Finalize find_package
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args( ${CMAKE_FIND_PACKAGE_NAME}
  REQUIRED_VARS NetCDF_INCLUDE_DIRS NetCDF_LIBRARIES
  VERSION_VAR NetCDF_VERSION
  HANDLE_COMPONENTS )

if( ${CMAKE_FIND_PACKAGE_NAME}_FOUND AND NOT ${CMAKE_FIND_PACKAGE_NAME}_FIND_QUIETLY )
  message( STATUS "Find${CMAKE_FIND_PACKAGE_NAME} defines targets:" )
  message( STATUS "  - NetCDF_CONFIG_EXECUTABLE [${NetCDF_CONFIG_EXECUTABLE}]")
  message( STATUS "  - NetCDF_PARALLEL [${NetCDF_PARALLEL}]")
  foreach( _comp ${_search_components} )
    string( TOUPPER "${_comp}" _COMP )
    if( ${CMAKE_FIND_PACKAGE_NAME}_${_arg_${_COMP}}_FOUND )
      get_filename_component(_root ${NetCDF_${_comp}_INCLUDE_DIR}/.. ABSOLUTE)
      if( NetCDF_${_comp}_LIBRARY_SHARED )
        message( STATUS "  - NetCDF::NetCDF_${_comp} [SHARED] [Root: ${_root}] Lib: ${NetCDF_${_comp}_LIBRARY} ")
      else()
        message( STATUS "  - NetCDF::NetCDF_${_comp} [STATIC] [Root: ${_root}] Lib: ${NetCDF_${_comp}_LIBRARY} ")
      endif()
    endif()
  endforeach()
endif()

foreach( _prefix NetCDF NetCDF4 NETCDF NETCDF4 ${CMAKE_FIND_PACKAGE_NAME} )
  set( ${_prefix}_INCLUDE_DIRS ${NetCDF_INCLUDE_DIRS} )
  set( ${_prefix}_LIBRARIES    ${NetCDF_LIBRARIES})
  set( ${_prefix}_VERSION      ${NetCDF_VERSION} )
  set( ${_prefix}_FOUND        ${${CMAKE_FIND_PACKAGE_NAME}_FOUND} )
  set( ${_prefix}_CONFIG_EXECUTABLE ${NetCDF_CONFIG_EXECUTABLE} )
  set( ${_prefix}_PARALLEL ${NetCDF_PARALLEL} )
  
  foreach( _comp ${_search_components} )
    string( TOUPPER "${_comp}" _COMP )
    set( _arg_comp ${_arg_${_COMP}} )
    set( ${_prefix}_${_comp}_FOUND     ${${CMAKE_FIND_PACKAGE_NAME}_${_arg_comp}_FOUND} )
    set( ${_prefix}_${_COMP}_FOUND     ${${CMAKE_FIND_PACKAGE_NAME}_${_arg_comp}_FOUND} )
    set( ${_prefix}_${_arg_comp}_FOUND ${${CMAKE_FIND_PACKAGE_NAME}_${_arg_comp}_FOUND} )

    set( ${_prefix}_${_comp}_LIBRARIES     ${NetCDF_${_comp}_LIBRARIES} )
    set( ${_prefix}_${_COMP}_LIBRARIES     ${NetCDF_${_comp}_LIBRARIES} )
    set( ${_prefix}_${_arg_comp}_LIBRARIES ${NetCDF_${_comp}_LIBRARIES} )

    set( ${_prefix}_${_comp}_INCLUDE_DIRS     ${NetCDF_${_comp}_INCLUDE_DIRS} )
    set( ${_prefix}_${_COMP}_INCLUDE_DIRS     ${NetCDF_${_comp}_INCLUDE_DIRS} )
    set( ${_prefix}_${_arg_comp}_INCLUDE_DIRS ${NetCDF_${_comp}_INCLUDE_DIRS} )
  endforeach()
endforeach()
