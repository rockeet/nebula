message(">>>> Configuring third party for '${PROJECT_NAME}' <<<<")
# The precedence to decide NEBULA_THIRDPARTY_ROOT is:
#   1. The path defined with CMake argument, i.e -DNEBULA_THIRDPARTY_ROOT=path
#   2. ${CMAKE_BINARY_DIR}/third-party/install, if exists
#   3. The path specified with environment variable NEBULA_THIRDPARTY_ROOT=path
#   4. /opt/vesoft/third-party, if exists
#   5. At last, one copy will be downloaded and installed to ${CMAKE_BINARY_DIR}/third-party/install

set(NEBULA_THIRDPARTY_VERSION "3.3")

if(${DISABLE_CXX11_ABI})
    SET(NEBULA_THIRDPARTY_ROOT ${CMAKE_BINARY_DIR}/third-party-98/install)
    if(NOT EXISTS ${CMAKE_BINARY_DIR}/third-party-98/install)
        message(STATUS "Install abi 98 third-party")
        include(InstallThirdParty)
    endif()
else()
    if("${NEBULA_THIRDPARTY_ROOT}" STREQUAL "")
        if(EXISTS ${CMAKE_BINARY_DIR}/third-party/install)
            SET(NEBULA_THIRDPARTY_ROOT ${CMAKE_BINARY_DIR}/third-party/install)
        elseif(NOT $ENV{NEBULA_THIRDPARTY_ROOT} STREQUAL "")
            SET(NEBULA_THIRDPARTY_ROOT $ENV{NEBULA_THIRDPARTY_ROOT})
        elseif(EXISTS /opt/vesoft/third-party/${NEBULA_THIRDPARTY_VERSION})
            SET(NEBULA_THIRDPARTY_ROOT "/opt/vesoft/third-party/${NEBULA_THIRDPARTY_VERSION}")
        else()
            include(InstallThirdParty)
        endif()
    endif()
endif()

if(NOT ${NEBULA_THIRDPARTY_ROOT} STREQUAL "")
    print_config(NEBULA_THIRDPARTY_ROOT)
    file(READ ${NEBULA_THIRDPARTY_ROOT}/version-info third_party_build_info)
    message(STATUS "Build info of nebula third party:\n${third_party_build_info}")
    list(INSERT CMAKE_INCLUDE_PATH 0 ${NEBULA_THIRDPARTY_ROOT}/include)
    list(INSERT CMAKE_LIBRARY_PATH 0 ${NEBULA_THIRDPARTY_ROOT}/lib)
    list(INSERT CMAKE_LIBRARY_PATH 0 ${NEBULA_THIRDPARTY_ROOT}/lib64)
    list(INSERT CMAKE_PROGRAM_PATH 0 ${NEBULA_THIRDPARTY_ROOT}/bin)
    include_directories(SYSTEM ${NEBULA_THIRDPARTY_ROOT}/include)
    link_directories(
        ${NEBULA_THIRDPARTY_ROOT}/lib
        ${NEBULA_THIRDPARTY_ROOT}/lib64
    )
    if(USE_TOPLINGDB)
        if(EXISTS "${NEBULA_THIRDPARTY_ROOT}/include/rocksdb"
           OR EXISTS "${NEBULA_THIRDPARTY_ROOT}/lib/librocksdb.a"
           OR EXISTS "${NEBULA_THIRDPARTY_ROOT}/lib64/librocksdb.a")
            message(STATUS "Removing bundled RocksDB from ${NEBULA_THIRDPARTY_ROOT}")
            file(REMOVE_RECURSE "${NEBULA_THIRDPARTY_ROOT}/include/rocksdb")
            file(REMOVE "${NEBULA_THIRDPARTY_ROOT}/lib/librocksdb.a")
            file(REMOVE "${NEBULA_THIRDPARTY_ROOT}/lib64/librocksdb.a")
        endif()
        if(EXISTS "${NEBULA_THIRDPARTY_ROOT}/include/rocksdb"
           OR EXISTS "${NEBULA_THIRDPARTY_ROOT}/lib/librocksdb.a"
           OR EXISTS "${NEBULA_THIRDPARTY_ROOT}/lib64/librocksdb.a")
            message(FATAL_ERROR
                "USE_TOPLINGDB=ON but bundled RocksDB still exists under ${NEBULA_THIRDPARTY_ROOT}")
        endif()
    endif()
endif()

if(NOT ${NEBULA_OTHER_ROOT} STREQUAL "")
    string(REPLACE ":" ";" DIR_LIST ${NEBULA_OTHER_ROOT})
    list(LENGTH DIR_LIST len)
    foreach(DIR IN LISTS DIR_LIST )
        list(INSERT CMAKE_INCLUDE_PATH 0 ${DIR}/include)
        list(INSERT CMAKE_LIBRARY_PATH 0 ${DIR}/lib)
        list(INSERT CMAKE_PROGRAM_PATH 0 ${DIR}/bin)
        include_directories(SYSTEM ${DIR}/include)
        link_directories(${DIR}/lib)
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -L ${DIR}/lib")
    endforeach()
endif()

print_config(CMAKE_INCLUDE_PATH)
print_config(CMAKE_LIBRARY_PATH)
print_config(CMAKE_PROGRAM_PATH)

execute_process(
    COMMAND ldd --version
    COMMAND head -1
    COMMAND cut -d ")" -f 2
    COMMAND cut -d " " -f 2
    OUTPUT_VARIABLE GLIBC_VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
print_config(GLIBC_VERSION)

if (GLIBC_VERSION VERSION_LESS "2.17")
    set(GETTIME_LIB rt)
else()
    set(GETTIME_LIB)
endif()

# Breakpad
if (ENABLE_BREAKPAD)
    if (NOT ${CMAKE_BUILD_TYPE} STREQUAL "Debug" AND NOT ${CMAKE_BUILD_TYPE} STREQUAL "RelWithDebInfo")
	    MESSAGE(FATAL_ERROR "Breakpad need debug info.")
    endif()
endif()
if (NOT ${CMAKE_HOST_SYSTEM_PROCESSOR} MATCHES "x86_64")
    set(ENABLE_BREAKPAD OFF)
endif()
if (ENABLE_BREAKPAD)
    add_compile_options(-DENABLE_BREAKPAD=1)
endif()

message("")

find_package(Bzip2 REQUIRED)
find_package(DoubleConversion REQUIRED)
find_package(Fatal REQUIRED)
find_package(Fbthrift REQUIRED)
find_package(Folly REQUIRED)
find_package(Gflags REQUIRED)
find_package(Glog REQUIRED)
find_package(Googletest REQUIRED)
if(ENABLE_JEMALLOC)
    find_package(Jemalloc REQUIRED)
    add_definitions(-DENABLE_JEMALLOC)
endif()
find_package(Libevent REQUIRED)
find_package(Proxygen REQUIRED)
if(USE_TOPLINGDB)
    if(NOT "${EXTERNAL_TOPLINGDB_ROOT}" STREQUAL "")
        set(TOPLINGDB_ROOT ${EXTERNAL_TOPLINGDB_ROOT})
        set(TOPLINGDB_NEEDS_BUILD FALSE)
        set(TOPLINGDB_PREBUILT TRUE)
    elseif(NOT "$ENV{EXTERNAL_TOPLINGDB_ROOT}" STREQUAL "")
        set(TOPLINGDB_ROOT $ENV{EXTERNAL_TOPLINGDB_ROOT})
        set(TOPLINGDB_NEEDS_BUILD FALSE)
        set(TOPLINGDB_PREBUILT TRUE)
    else()
        set(TOPLINGDB_PREBUILT FALSE)
        include(InstallToplingDB)
    endif()
    if(TOPLINGDB_PREBUILT)
        if(NOT EXISTS "${TOPLINGDB_ROOT}/librocksdb.so")
            message(FATAL_ERROR "External ToplingDB at ${TOPLINGDB_ROOT} is missing librocksdb.so")
        endif()
    endif()
    if(EXISTS "${TOPLINGDB_ROOT}/librocksdb.so")
        execute_process(
            COMMAND sh -c "ldd \"${TOPLINGDB_ROOT}/librocksdb.so\" | grep -q libjemalloc && exit 1 || exit 0"
            RESULT_VARIABLE _toplingdb_jemalloc_dylib)
        if(NOT _toplingdb_jemalloc_dylib EQUAL 0)
            message(FATAL_ERROR
                "${TOPLINGDB_ROOT}/librocksdb.so must not dynamically link libjemalloc")
        endif()
    endif()
    print_config(TOPLINGDB_ROOT)

    set(CMAKE_SKIP_RPATH FALSE)
    set(CMAKE_BUILD_RPATH "${TOPLINGDB_ROOT}")
    set(CMAKE_INSTALL_RPATH "\$ORIGIN/../lib")
    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH FALSE)

    install(CODE "
        file(GLOB _toplingdb_so \"${TOPLINGDB_ROOT}/librocksdb.so*\")
        if(NOT _toplingdb_so)
            message(FATAL_ERROR \"ToplingDB librocksdb.so* not found under ${TOPLINGDB_ROOT}\")
        endif()
        file(MAKE_DIRECTORY \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/lib\")
        execute_process(
            COMMAND cp -a \${_toplingdb_so} \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/lib/\"
            RESULT_VARIABLE _toplingdb_cp_ret)
        if(NOT _toplingdb_cp_ret EQUAL 0)
            message(FATAL_ERROR \"cp -a librocksdb.so* failed: \${_toplingdb_cp_ret}\")
        endif()
    " COMPONENT graph)
    install(
        FILES
            ${CMAKE_SOURCE_DIR}/conf/topling-mimic-rocksdb.yaml
            ${CMAKE_SOURCE_DIR}/conf/topling-enterprise.yaml
        PERMISSIONS
            OWNER_READ
            GROUP_READ
            WORLD_READ
        DESTINATION
            etc
        COMPONENT
            graph
    )
endif()
find_package(Rocksdb REQUIRED)
find_package(Snappy REQUIRED)
find_package(Wangle REQUIRED)
find_package(ZLIB REQUIRED)
find_package(Zstd REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(Boost REQUIRED)
find_package(Libunwind REQUIRED)
find_package(BISON 3.0.5 REQUIRED)
include(MakeBisonRelocatable)
find_package(FLEX REQUIRED)
find_package(LibLZMA REQUIRED)
find_package(Fizz REQUIRED)
find_package(Sodium REQUIRED)
if (ENABLE_BREAKPAD)
    find_package(Breakpad REQUIRED)
endif()

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -L ${NEBULA_THIRDPARTY_ROOT}/lib")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -L ${NEBULA_THIRDPARTY_ROOT}/lib64")

# All thrift libraries
set(THRIFT_LIBRARIES
    thriftcpp2
    async
    thriftprotocol
    transport
    concurrency
    thriftfrozen2
    thrift-core
    rpcmetadata
    thriftmetadata
    wangle
    fizz
    sodium
)

set(PROXYGEN_LIBRARIES
    proxygenhttpserver
    proxygen
    wangle
    fizz
    sodium
)

set(ROCKSDB_LIBRARIES ${Rocksdb_LIBRARY})

# All compression libraries
set(COMPRESSION_LIBRARIES bz2 snappy zstd z lz4)
if (LIBLZMA_FOUND)
    include_directories(SYSTEM ${LIBLZMA_INCLUDE_DIRS})
    list(APPEND COMPRESSION_LIBRARIES ${LIBLZMA_LIBRARIES})
endif()

if (NOT ENABLE_JEMALLOC OR ENABLE_ASAN OR ENABLE_UBSAN)
    set(JEMALLOC_LIB )
else()
    set(JEMALLOC_LIB jemalloc)
endif()

if (Breakpad_FOUND)
    include_directories(AFTER SYSTEM ${Breakpad_INCLUDE_DIR}/breakpad)
endif()

message(">>>> Configuring third party for '${PROJECT_NAME}' done <<<<")
