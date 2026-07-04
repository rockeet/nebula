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
