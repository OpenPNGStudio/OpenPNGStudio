@echo off
setlocal enabledelayedexpansion

if /i "%RELEASE_BUILD%"=="true" (
    set RELEASE_BUILD=RelWithDebInfo
) else (
    set RELEASE_BUILD=Debug
)

mkdir build
cd build
cmake -G "Ninja" -DCMAKE_GENERATOR_PLATFORM="" -DCMAKE_BUILD_TYPE="%RELEASE_BUILD%" -DCMAKE_INSTALL_PREFIX=".\miniroot" -DCMAKE_C_COMPILER=cl -DCMAKE_CXX_COMPILER=cl ..
if errorlevel 1 exit /b %errorlevel%

ninja
if errorlevel 1 exit /b %errorlevel%

ninja install
if errorlevel 1 exit /b %errorlevel%
cd ..

.\c3-windows-Release\c3c.exe build OpenPNGStudio-windows-x64
if errorlevel 1 exit /b %errorlevel%

.\c3-windows-Release\c3c.exe build opng
if errorlevel 1 exit /b %errorlevel%
