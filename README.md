# Template WxWidgets CMake Project

The purpose of this repo is to provide an easy cmake template for cross platform c++ projects with versions 3.1+ of wxWdigets, and with opengl support enabled.

Provided under the GNU 3.0 General Public License. 
No warranty is expressed or implied, including suitability for any purpose.

Incorporates some logic from findwxwidgets.cmake. I experienced issues using findwxidgets.cmake in Windows with wxWidgets 3.1.4, and wanted to create a method which always calls wx-config. In call_wx_config.cmake, the build  directory of wxwidgets can be specified with a cache variable. This makes it easy to use separate debug and release builds of wxwidgets in their own folders, by changing a command line argument when setting up the debug and release builds of the new project. When setting msys to ON, it runs inside a msys2 type shell in Windows (automtaically handling the differences in path formatting).

## Building the example project on Windows

These instructions are based on the MinGW compiler suite for Windows, but others are avilable.

**Install mingw-get and use it to install the following packages**
- mingw-binutils-bin
- ming32-make-bin
- mingw-gcc-bin
- mingw-g++-bin
- mingw-gdb-bin
**Install CMake**
**Install MSYS2 console**
**Downlad wxWidgets to a folder** (for example c:\wxWidgets 3.1.4)**

**Open MSYS2 console and make sure the MinGW\bin and CMake\bin folders are in the PATH. **
For example:
```
export PATH=$PATH:/c/Program\ Files/CMake/bin
export PATH=$PATH:/c/MinGW/bin
```

**Navigate to wxWidgets root folder and build the release and debug configurations in their own subdirectories**
```
cd /c/wxWidgets-3.1.4
mkdir build-debug
cd build-debug
../configure --enable-debug --disable-shared --disable-dependency-tracking --with-opengl
make
cd ..
mkdir build-release
cd build-release
../configure --disable-shared --disable-dependency-tracking --with-opengl
make
```

**Navigate to this project's folder and setup the debug and release builds with CMake**
```
cd /c/<path to template_wxwidgets_cmake>
mkdir build-debug
cd build-debug
cmake .. -G "MinGW Makefiles" -Dwx_root_dir=/c/wxWidgets-3.1.4 -Dwx_build_dir=/c/wxWidgets-3.1.4/build-debug -Dmsys=ON -DCMAKE_BUILD_TYPE=Debug
cmake --build .
cd ..
mkdir build-release
cd build-release
cmake .. -G "MinGW Makefiles" -Dwx_root_dir=/c/wxWidgets-3.1.4 -Dwx_build_dir=/c/wxWidgets-3.1.4/build-release -Dmsys=ON -DCMAKE_BUILD_TYPE=Release
cmake --build .
```

**Done**
Now, further calls to cmake --build . inside build-release and build-debug can be made from a regular windows shell, for instance Powershell in VS Code.
We only need to run cmake configure in these directories from a cygwin/msys style shell due to wx-config being a shell script.

## Building the example project on Linux

**Download and extract wxWidgets to a folder**
```
<download wxWidgets-3.1.4 from the web>
tar -xjvf wxWidgets-3.1.4.tar.bz
```

**Make sure gtk and opengl libraries are installed**
```
sudo apt-get install libgtk2.0-dev
sudo apt-get install freeglut3-dev
```

**Navigate to wxWidgets root folder and build the release and debug configurations in their own subdirectories**
```
cd ~/wxWidgets-3.1.4
mkdir build-debug
cd build-debug
../configure --with-gtk --enable-debug --disable-shared --with-opengl
make
cd ..
mkdir build-release
cd build-release
../configure --with-gtk --disable-shared --with-opengl
make
```

**Install CMake and make sure CMake's bin folder is in the PATH environment variable**

**Navigate to this project's folder and build the wxwidgets hello world test.cpp to prove the setup works**
```
mkdir build-debug
cd build-debug
cmake .. -G "Unix Makefiles" -Dwx_build_dir=<path to the build-debug folder earlier> -DCMAKE_BUILD_TYPE=Debug
cmake --build .
./test
cd ..
mkdir build-release
cd build-release
cmake .. -G "Unix Makefiles" -Dwx_build_dir=<path to the build-release folder earlier> -DCMAKE_BUILD_TYPE=Release
cmake --build .
./test
```