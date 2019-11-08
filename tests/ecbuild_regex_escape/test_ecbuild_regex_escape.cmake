cmake_minimum_required( VERSION 3.6 FATAL_ERROR )

find_package( ecbuild REQUIRED )
include( ecbuild_regex_escape )

set(testno 1)
foreach(str "bla" "1.2" "a(b)" "a[b]" "x++" "a\\0" "x*" "x?" "a|b" "$v" "^a")
    message("Escaping '${str}'")
    ecbuild_regex_escape("${str}" test${testno})
    message("-> ${test${testno}}")
    string(REGEX REPLACE "${test${testno}}" "match" test${testno}_match "${str}")
    if(NOT "${test${testno}_match}" STREQUAL "match")
      message(FATAL_ERROR "ecbuild_regex_escape not working as expected")
    endif()
    math(EXPR testno "${testno} + 1")
endforeach()

