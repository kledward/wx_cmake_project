# #################################################################################################
#
# File: call_wx_config.cmake
# Date: 11/27/2020
# Author: Kyle Edwards (edwarky8 at gmail dot com)
# Description: call_wx_config macro
#
# 
# Command line arguments / CACHE variables needed by call_wx_config
#   -Dwx_root_dir - needed when msys=ON, this is the root directory were wx-widgets was unzipped
#
#   -Dwx_build_dir - needed if wx-config does not live in $PATH or to specify a specific build.  
#                    set to the directory where wxwidgets was built and where wx-config lives
#
#   -Dmsys=(ON/OFF) - default OFF. set this to ON if running in windows. In windows, cmake should be
#                     run from a  msys2/MinTTY type shell, where it calls wx-config (a shell script)
#
#   -Dwx_config_args - this is --gl-libs;--libs;--cxxflags by default
#
#
# Here are the high level steps:
#	- (if msys=ON) verify wx_build_dir and wx_root_dir are specified
#   - (if msys=ON) convert wx_build_dir and wx_root_dir to linux style paths for use with wx-config
#   - call wx-config, or wx_build_dir\wx-config if wx_build_dir specified
#	- convert a few flags which take an argument after a space back into a single flag
#   - sort all flags in wx-config output into wx_cxx_flags, wx_include_dirs, wx_libs, wx_defines
#   - (if msys=ON) convert all instances of wx_build_dir/wx_root_dir in wx_libs and and wx_include_dirs to Windows style paths
#   - set all target options with wx_cxx_flags, wx_include_dirs, wx_libs, wx_defines
#
# In Windows, this must be run from a MinTTY/msys2 type shell which can run wx-config (a shell script).
# Also, msys=ON, and wx_build_dir/wx_root_dir must be specified when running this in Windows. On other platforms 
# possible to leave them off if wx-config is in the PATH
#
# Provided under the GNU 3.0 General Public License. 
# No warranty is expressed or implied, including suitability for any purpose.
# 
# Incorporates some logic from findwxwidgets.cmake.
#
# ##################################################################################################

#
# Command line arguments
#
set(wx_root_dir CACHE STRING "Root directory of wxwidgets. If calling from msys/cygwin, this could be /c/wxWidgets-3.1.4")
set(wx_build_dir CACHE STRING "Directory where wxwidgets was built If calling from msys/cygwin, this is /c/wxWidgets-3.1.4/build")
set(wx_config_args "--gl-libs;--libs;--cxxflags" CACHE STRING "Arguments passed to wx-config to retrieve compiler flags")
option(msys OFF "Set this to on if you are using cmake from msys or other Windows shell with linux style paths" )

# These variables control the operation of call_wx_config
set(shell "sh")
set(shell_args "")
set(wx_config "wx-config")

# These variables get populated by call_wx_config
set(wx_cxx_flags "")
set(wx_include_dirs "")
set(wx_libs "")
set(wx_defines "")

macro(debug_msg msg)
	#message(${msg})
endmacro()

macro(debug_verbose_msg msg)
	#message(${msg})
endmacro()

#
# Function to execute cygpath and convert a path to linux/msys format. use flag=-w to convert from msys to windows format
# This function is only used when -Dmsys=ON is specified, meaning this is run from inside a linux-style shell in Windows.
#
function(cygpath dir_var dir flag)
	execute_process(
		COMMAND "cygpath" ${flag} ${dir}
		OUTPUT_VARIABLE dir_output
		RESULT_VARIABLE result
	)
	# remove newlines, spaces at the start and end, and convert \ to / for uniformity
	string(REPLACE "\r\n" "" dir_output "${dir_output}")
	string(REPLACE "\n" "" dir_output "${dir_output}")
	string(REPLACE "\\" "/" dir_output "${dir_output}")
	string(STRIP dir_output "${dir_output}")

	if(result EQUAL 0)
		set(${dir_var} ${dir_output} PARENT_SCOPE)
	else()
		message(WARNING "Could not call cygpath, check that it is accessible from the shell. Folder names may be incorrect as a result.")
	endif()
endfunction()

#
# Macro call_wx_config, main functionality of the file
#
macro(call_wx_config target_name)
	debug_msg("starting call_wx_config, wx_root_dir=${wx_root_dir}, wx_build_dir=${wx_build_dir}, msys=${msys}")
	# 
	# if we are using msys, make sure the wx_root_dir and wX_build_dir functions are using unix style format, as we will be making shell
	# calls to wx-config. Sometimes cmake will convert these to windows format, so this step is necessary
	#
	if(msys)
		if (wx_root_dir STREQUAL "" OR wx_build_dir STREQUAL "")
			message(FATAL_ERROR "wx_root_dir and/or wx_build_dir not specified. These are necessary in MSYS Mode."
								"Use -Dwx_root_dir=... and -Dwx_build_dir=...")
		endif()
		cygpath(wx_root_dir "${wx_root_dir}" "")
		cygpath(wx_build_dir "${wx_build_dir}" "")
	endif()

	#
	# Construct the shell command then execute wx-config
	#
	if(wx_build_dir)
		set(wx_config "${wx_build_dir}/${wx_config}")
		debug_verbose_msg("wx_config=${wx_config}")
	endif()

	execute_process(
		COMMAND ${shell} ${shell_args} "${wx_config}" ${wx_config_args}
		OUTPUT_VARIABLE response
			RESULT_VARIABLE result
		)

	#
	# If running wx-config was successful, process the returned values
	#
	if (${result} EQUAL 0)
		message(STATUS "Successfully called wx-config")
		# 
		# Save the list of returned flags in wx_flags
		#
		string(STRIP "${response}" response)
		separate_arguments(wx_flags NATIVE_COMMAND "${response}")

		debug_verbose_msg("wx_flags=${wx_flags}")
		debug_verbose_msg("Processing arguments which include a space i.e. -arch ...")

		#
		# Flags which take an argument after a space should be converted back to a single flag 
		#
		string(REPLACE "-framework;" "-framework " wx_flags "${wx_flags}")
		string(REPLACE "-weak_framework;" "-weak_framework " wx_flags "${wx_flags}")
		string(REPLACE "-arch;" "-arch " wx_flags "${wx_flags}")
		string(REPLACE "-isysroot;" "-isysroot " wx_flags "${wx_flags}")

		debug_verbose_msg("wx_flags=${wx_flags}")

		# 
		# Separate the flags into their own lists 
		# wx_defines = content of flags with -D
		# wx_include_dirs = content of flags with -I
		# wx_libs = content of flags with -l or -L
		# wx_cxx_flags = everything else, with the raw flag
		#
		debug_verbose_msg("sorting arguments into wx_defines, wx_include_dirs, wx_libs, and wx_cxx_flags")
		foreach (arg ${wx_flags})
			string(LENGTH ${arg} arg_len)
			
			# save the content of the argument after the first 2 chars (-I/-D/-l etc)
			if (${arg_len} GREATER 2)
				string(SUBSTRING ${arg} 2 -1 arg_content)
			else()
				set(arg_content "")
			endif()

			debug_verbose_msg("processing arg=${arg} arg_content=${arg_content}")
			
			# -I flags go into wx_include_dirs
			if(${arg} MATCHES "^-I")
				set(wx_include_dirs "${wx_include_dirs}" "${arg_content}")
				debug_verbose_msg("added ${arg_content} to wx_include_dirs")

			# -D flags go into wx_defines
			elseif (${arg} MATCHES "^-D")
				set(wx_defines "${wx_defines}" "${arg_content}")
				debug_verbose_msg("added ${arg_content} to wx_defines")
			
			# -L and -l flags go into wx_libs
			elseif (${arg} MATCHES "^-l" OR ${arg} MATCHES "^-L")
				set(wx_libs "${wx_libs}" "${arg}")
				debug_verbose_msg("added ${arg} to wx_libs")			
			
			# args that are just a file in the build directory go in wx_libs
			elseif (${arg} MATCHES ${wx_build_dir})			
				set(wx_libs "${wx_libs}" "${arg}")
				debug_verbose_msg("added ${arg} to wx_libs")			

			# everything else goes into wx_cxx_flags
			else()
				set(wx_cxx_flags "${wx_cxx_flags}" "${arg}")
				debug_verbose_msg("added ${arg} to wx_cxx_flags")
			endif()
		endforeach()


		#
		# If msys variable is set, which should be done by the caller if running in an msys style environment, convert paths from
		# cygwin style /c/folder... to a format which will work when cmake.exe is searching for the paths. cygpath -w is the utility 
		# for this
		#
		if(msys)
			# execute cygpath to convert wx_build_dir and wx_root_dir to windows format
			foreach(wx_dir ${wx_build_dir} ${wx_root_dir})
				#call cygpath to convert wx_dir to windows format (-w)
				cygpath(wx_dir_win "${wx_dir}" "-w")
				debug_verbose_msg("converted ${wx_dir} to ${wx_dir_win} using cygpath.")
				
				if (result EQUAL 0)
					# replace the old style path with the new style path wherever it occurs in wx_flags, and display a message
					string(REPLACE "${wx_dir}" "${wx_dir_win}" wx_include_dirs "${wx_include_dirs}" )
					string(REPLACE "${wx_dir}" "${wx_dir_win}" wx_libs "${wx_libs}" )
					string(REPLACE "${wx_dir}" "${wx_dir_win}" wx_cxx_flags "${wx_cxx_flags}" )
					string(REPLACE "${wx_dir}" "${wx_dir_win}" wx_defines "${wx_defines}" )

					debug_msg("Successfully replaced unix-style path ${wx_dir} with ${wx_dir_win}, because msys variable was set")
				else()
					# if cygpath call was not successful, display a warning and abort the foreach loop
					message(WARNING "msys is set, but is script is unable to call cygpath to convert paths to windows format."
							"cmake --build may fail due to paths in /c/folder/... format which is unrecognized outside the shell program."
							"Check if cygpath utility is available")
					break()
				endif()
			endforeach()
		endif()

		#
		# Apply the values to the target
		#
		target_link_options(${target_name} PUBLIC "${wx_cxx_flags}")
		target_compile_options(${target_name} PUBLIC "${wx_cxx_flags}")
		target_compile_definitions(${target_name} PUBLIC "${wx_defines}")
		target_include_directories(${target_name} PUBLIC "${wx_include_dirs}")
		target_link_libraries(${target_name} PUBLIC "${wx_libs}")
		
		# Done, show message
		message(STATUS "Applied wx-config flags to target ${target_name}")
		debug_msg("wx_cxx_flags=${wx_cxx_flags}")
		debug_msg("wx_include_dirs=${wx_include_dirs}")
		debug_msg("wx_libs=${wx_libs}")
		debug_msg("wx_defines=${wx_defines}")
	#
	# if calling wx-config was not successful, display error message
	#
	else()
		message(FATAL_ERROR "Could not call wx-config ${wx_config_arg}. Nothing applied to the target."
				"Check if shell variable is set to the correct shell executable (for instance: sh)."
				"Check if wx_dir variable is set to the directory where wxwidgets was compiled, which contains the wx-config shell script.")
	endif()
endmacro()