# #################################################################################################
#
# File: CMakeLists.txt
# Date: 11/27/2020
# Author: Kyle Edwards (edwarky8 at gmail dot com)
# Description: Test CMakeLists for template_wxwidgets_cmake project. See Readme.md for instructions
# on building. 
# ##################################################################################################


#
# cmake project setup
#
set(PROJ_NAME test)
cmake_minimum_required(VERSION 3.1)
project(${PROJ_NAME})

add_executable(${PROJ_NAME}
  test.cpp
)

#
# Call wx-config, this relies on CACHE variables wx_root_dir and wx_build_dir being specified
# This will set the compile and linker flags needed to use wxwidgets
#
include(call_wx_config.cmake)
call_wx_config(${PROJ_NAME})
