find_package(Git)

set(toplingdb_src_dir ${CMAKE_BINARY_DIR}/toplingdb)
set(toplingdb_lib ${toplingdb_src_dir}/librocksdb.so)

if(NOT EXISTS ${toplingdb_src_dir})
    message(STATUS "Cloning ToplingDB from https://github.com/topling/toplingdb.git ...")
    execute_process(
        COMMAND ${GIT_EXECUTABLE} clone https://github.com/topling/toplingdb.git ${toplingdb_src_dir}
        RESULT_VARIABLE clone_status
        ERROR_VARIABLE clone_error
    )
    if(NOT ${clone_status} EQUAL 0)
        file(REMOVE_RECURSE ${toplingdb_src_dir})
        message(FATAL_ERROR "Failed to clone ToplingDB from https://github.com/topling/toplingdb.git: ${clone_error}")
    endif()
    if(NOT EXISTS ${toplingdb_src_dir}/include/rocksdb/db.h)
        file(REMOVE_RECURSE ${toplingdb_src_dir})
        message(FATAL_ERROR "Cloned ToplingDB source tree is missing include/rocksdb/db.h at ${toplingdb_src_dir}")
    endif()
elseif(NOT EXISTS ${toplingdb_src_dir}/include/rocksdb/db.h)
    message(FATAL_ERROR "ToplingDB source tree at ${toplingdb_src_dir} is incomplete (missing include/rocksdb/db.h)")
endif()

set(topling_zip_dir ${toplingdb_src_dir}/sideplugin/topling-zip)
if(NOT EXISTS ${topling_zip_dir})
    message(STATUS "Cloning topling-zip from https://github.com/topling/topling-zip.git ...")
    file(MAKE_DIRECTORY ${toplingdb_src_dir}/sideplugin)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} clone https://github.com/topling/topling-zip.git topling-zip
        WORKING_DIRECTORY ${toplingdb_src_dir}/sideplugin
        RESULT_VARIABLE topling_zip_clone_status
        ERROR_VARIABLE topling_zip_clone_error
    )
    if(NOT ${topling_zip_clone_status} EQUAL 0)
        file(REMOVE_RECURSE ${topling_zip_dir})
        message(FATAL_ERROR "Failed to clone topling-zip from https://github.com/topling/topling-zip.git: ${topling_zip_clone_error}")
    endif()
    execute_process(
        COMMAND ${GIT_EXECUTABLE} submodule update --init --recursive
        WORKING_DIRECTORY ${topling_zip_dir}
        RESULT_VARIABLE topling_zip_submodule_status
        ERROR_VARIABLE topling_zip_submodule_error
    )
    if(NOT ${topling_zip_submodule_status} EQUAL 0)
        file(REMOVE_RECURSE ${topling_zip_dir})
        message(FATAL_ERROR "Failed to init topling-zip submodules: ${topling_zip_submodule_error}")
    endif()
    if(NOT EXISTS ${topling_zip_dir}/src)
        file(REMOVE_RECURSE ${topling_zip_dir})
        message(FATAL_ERROR "Cloned topling-zip source tree is missing src/ at ${topling_zip_dir}")
    endif()
elseif(NOT EXISTS ${topling_zip_dir}/src)
    message(FATAL_ERROR "topling-zip source tree at ${topling_zip_dir} is incomplete (missing src/)")
endif()

set(TOPLINGDB_ROOT ${toplingdb_src_dir})

if(EXISTS ${toplingdb_lib})
    set(TOPLINGDB_NEEDS_BUILD FALSE)
    message(STATUS "ToplingDB shared library already built at ${toplingdb_lib}")
else()
    set(TOPLINGDB_NEEDS_BUILD TRUE)
    message(STATUS "ToplingDB will be built when running 'cmake --build'")
endif()

add_custom_command(
    OUTPUT ${toplingdb_lib}
    COMMAND "$(MAKE)" -C ${toplingdb_src_dir}
        DEBUG_LEVEL=0 DISABLE_JEMALLOC=1 TOPLING_USE_DYNAMIC_TLS=1
        CC=${CMAKE_C_COMPILER} CXX=${CMAKE_CXX_COMPILER} shared_lib
    COMMENT "Building ToplingDB shared library"
)
add_custom_target(toplingdb_shared_lib ALL DEPENDS ${toplingdb_lib})
