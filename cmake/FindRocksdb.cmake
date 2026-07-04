# - Try to find Rocksdb includes dirs and libraries
#
# Usage of this module as follows:
#
#     find_package(Rocksdb)
#
# Variables used by this module, they can change the default behaviour and need
# to be set before calling find_package:
#
# Variables defined by this module:
#
#  Rocksdb_FOUND            System has Rocksdb, include and lib dirs found
#  Rocksdb_INCLUDE_DIR      The Rocksdb includes directories.
#  Rocksdb_LIBRARY          The Rocksdb library.

if(USE_TOPLINGDB)
  find_path(Rocksdb_INCLUDE_DIR NAMES rocksdb/db.h
    PATHS "${TOPLINGDB_ROOT}/include" NO_DEFAULT_PATH)
  if(TOPLINGDB_NEEDS_BUILD AND NOT EXISTS "${TOPLINGDB_ROOT}/librocksdb.so")
    set(Rocksdb_LIBRARY "${TOPLINGDB_ROOT}/librocksdb.so")
  else()
    find_library(Rocksdb_LIBRARY NAMES librocksdb.so
      PATHS "${TOPLINGDB_ROOT}" PATH_SUFFIXES . lib lib64 NO_DEFAULT_PATH)
  endif()
  include_directories(BEFORE SYSTEM
      "${TOPLINGDB_ROOT}/include"
      "${TOPLINGDB_ROOT}/sideplugin/topling-zip/src"
      "${TOPLINGDB_ROOT}/sideplugin/topling-zip/boost-include"
  )
else()
  find_path(Rocksdb_INCLUDE_DIR NAMES rocksdb)
  find_library(Rocksdb_LIBRARY NAMES librocksdb.a)
endif()

if(Rocksdb_INCLUDE_DIR AND Rocksdb_LIBRARY)
    set(Rocksdb_FOUND TRUE)
    mark_as_advanced(
        Rocksdb_INCLUDE_DIR
        Rocksdb_LIBRARY
    )
endif()

if(NOT Rocksdb_FOUND)
    message(FATAL_ERROR "Rocksdb doesn't exist")
endif()
