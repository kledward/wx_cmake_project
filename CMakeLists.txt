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
# Call wx-config and apply all the settings to this build target
#
# In Windows:
# this requires CMake be run inside a shell (MSYS2 reccomended), with the following CACHE (command line)
# variables set, these are intended to be set as command line arguments when running cmake.
#
# wx_root_dir=<directory where wxwidgets source was extracted>
# wx_build_dir=<directory where wxwidgets was built>
# msys=ON
#
# On other platforms:
# Set wx_build_dir if wx-config is not in PATH or you want to use a specific build of wxwidgets
# in its own folder.
# 

include(call_wx_config.cmake)
call_wx_config(${PROJ_NAME})
