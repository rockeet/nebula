set(third_party_install_prefix ${CMAKE_BINARY_DIR}/third-party/install)
message(STATUS "Downloading prebuilt third party automatically...")
if(${CMAKE_CXX_COMPILER_ID} STREQUAL "Clang")
    if(NOT ${NEBULA_CLANG_USED_GCC_TOOLCHAIN} STREQUAL "")
        set(cxx_cmd ${NEBULA_CLANG_USED_GCC_TOOLCHAIN}/bin/g++)
    else()
        set(cxx_cmd ${CMAKE_CXX_COMPILER})
    endif()
else()
    set(cxx_cmd ${CMAKE_CXX_COMPILER})
endif()
if(${DISABLE_CXX11_ABI})
    set(cxx_cmd "${cxx_cmd} -D_GLIBCXX_USE_CXX11_ABI=0")
else()
    set(cxx_cmd "${cxx_cmd} -D_GLIBCXX_USE_CXX11_ABI=1")
endif()
message(STATUS "cxx_cmd: ${cxx_cmd}")
if(USE_TOPLINGDB)
    set(_remove_bundled_rocksdb_env REMOVE_BUNDLED_ROCKSDB=1)
else()
    set(_remove_bundled_rocksdb_env REMOVE_BUNDLED_ROCKSDB=0)
endif()
execute_process(
    COMMAND
        env CXX=${cxx_cmd} version=${NEBULA_THIRDPARTY_VERSION} ${_remove_bundled_rocksdb_env} ${CMAKE_SOURCE_DIR}/third-party/install-third-party.sh --prefix=${third_party_install_prefix}
    WORKING_DIRECTORY
        ${CMAKE_BINARY_DIR}
    RESULT_VARIABLE _third_party_install_status
)
if(NOT _third_party_install_status EQUAL 0)
    message(FATAL_ERROR "Third party installation failed with exit code ${_third_party_install_status}")
endif()

if(EXISTS ${third_party_install_prefix})
    set(NEBULA_THIRDPARTY_ROOT ${third_party_install_prefix})
endif()
unset(third_party_install_prefix)
