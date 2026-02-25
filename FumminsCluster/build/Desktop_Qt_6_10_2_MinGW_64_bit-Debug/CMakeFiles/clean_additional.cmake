# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "Debug")
  file(REMOVE_RECURSE
  "CMakeFiles\\appFumminsCluster_autogen.dir\\AutogenUsed.txt"
  "CMakeFiles\\appFumminsCluster_autogen.dir\\ParseCache.txt"
  "appFumminsCluster_autogen"
  )
endif()
