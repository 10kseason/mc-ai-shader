@echo off
setlocal

set "ROOT=%~dp0"
set "DIST=%ROOT%dist"
set "OUT=%DIST%\Client-GLSL-Shaderpack-Lab-1.20.1.zip"

if not exist "%DIST%" mkdir "%DIST%"
if exist "%OUT%" del /f /q "%OUT%"

pushd "%ROOT%"
tar -a -cf "%OUT%" shaders pack.mcmeta LICENSE.txt README.md WATER_REFLECTION_DIAGNOSIS.md
popd
if errorlevel 1 (
    echo Packaging failed.
    exit /b 1
)

echo Wrote %OUT%
