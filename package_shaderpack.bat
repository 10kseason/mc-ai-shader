@echo off
setlocal

set "ROOT=%~dp0"
set "DIST=%ROOT%dist"
set "VERSION=0.1.17"
set "OUT=%DIST%\Client-GLSL-Shaderpack-Lab-%VERSION%-mc1.20.1.zip"
set "ALIAS=%DIST%\Client-GLSL-Shaderpack-Lab-1.20.1.zip"

if not exist "%DIST%" mkdir "%DIST%"
if exist "%OUT%" del /f /q "%OUT%"
if exist "%ALIAS%" del /f /q "%ALIAS%"

pushd "%ROOT%"
tar -a -cf "%OUT%" shaders pack.mcmeta README.md README.ko.md WATER_REFLECTION_DIAGNOSIS.md BUMP_MAPPING_DIAGNOSIS.md GLASS_MATERIAL_DIAGNOSIS.md MATERIAL_DEBUG_DIAGNOSIS.md ADVANCED_ENHANCEMENT_DIAGNOSIS.md docs/shaderpack_enhancement_plan.md
popd
if errorlevel 1 (
    echo Packaging failed.
    exit /b 1
)

copy /y "%OUT%" "%ALIAS%" >nul
if errorlevel 1 (
    echo Alias copy failed.
    exit /b 1
)

echo Wrote %OUT%
echo Wrote %ALIAS%
