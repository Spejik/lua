# Copyright (c) 2021 spejik
# Currently supported Lua version: 5.4.3
# Currently supported Luau version: 0.503
# https://www.lua.org/download.html
Param (
    [string]$BuildFor = "lua",
    [string]$BuildConfig = "Release"
)

$root = $PSScriptRoot


if ($BuildFor -eq "luau")
{
    # Sync download
    (New-Object System.Net.WebClient).DownloadFile("https://github.com/Roblox/luau/archive/refs/tags/0.503.tar.gz", "$root\luau-0.503.tar.gz") | Out-Null
    cmd.exe /c "tar -xzf $root\luau-0.503.tar.gz"
    Remove-Item "$root\luau-0.503.tar.gz"
    
    $luau = "$root\luau-0.503"
    $cmake = "$luau\cmake"
    
    New-Item -Path $luau -Name "cmake" -ItemType "directory" -ErrorAction Ignore 
    Set-Location $cmake

    cmd.exe /c "cmake .. -DCMAKE_BUILD_TYPE=$BuildConfig"
    cmd.exe /c "cmake --build . --target Luau.Repl.CLI --config $BuildConfig"
    cmd.exe /c "cmake --build . --target Luau.Analyze.CLI --config $BuildConfig"
    Set-Location $root
}
elseif ($BuildFor -eq "lua") 
{
    $ver = "5.4.3"
    $v = "543"
    $lua = "$root\lua-$ver"
    $src = "$lua\src"

    # TODO: maybe use a better way to find these files?
    # Since right now we have to use where.exe cl/link/lib in VS's developer console
    $vsdir = "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.30.30705\bin\Hostx64\x64"
    $vc = "call ""C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"" &&"
    $cl = "$vc ""$vsdir\cl.exe"""
    $link = "$vc ""$vsdir\link.exe"""
    $lib = "$vc ""$vsdir\lib.exe"""


    # === Download
    # Download tar (pipe to null for sync)
    (New-Object System.Net.WebClient).DownloadFile("https://www.lua.org/ftp/lua-$ver.tar.gz", "$root\lua-$ver.tar.gz") | Out-Null
    # Validate
    if ((Get-FileHash -Algorithm SHA1 "$root\lua-$ver.tar.gz").Hash -ne "1dda2ef23a9828492b4595c0197766de6e784bc7")
    {
        Throw "Downloaded file does not match checksum"
    }
    # tar.exe comes with WSL
    cmd.exe /c "tar -xzf $root\lua-$ver.tar.gz"
    Remove-Item "$root\lua-$ver.tar.gz"


    # === Build
    Set-Location $src
    # Create output directories
    New-Item -Path $root -Name "include" -ItemType "directory" -ErrorAction Ignore

    # Build object files
    cmd.exe /c "$cl /MD /O2 /Ot /c /DLUA_BUILD_AS_DLL *.c"

    # Rename the exe objects, so they don't disrupt the next step
    Rename-Item lua.obj lua.o
    Rename-Item luac.obj luac.o

    # Link libraries and executables
    cmd.exe /c "$link /DLL /IMPLIB:lua$v.lib /OUT:lua$v.dll *.obj"# lua.dll (dynamic)
    cmd.exe /c "$link /OUT:lua.exe lua.o lua$v.lib"               # lua.exe
    cmd.exe /c "$lib /OUT:lua$v.lib *.obj"                        # lua.lib (static)
    cmd.exe /c "$link /OUT:luac.exe luac.o lua$v.lib"             # luac.exe
    Set-Location $root


    # === Copy
    $includes = ("lua.h", "luaconf.h", "lualib.h", "lauxlib.h", "lua.hpp")
    Copy-Item "$src\lua$v.lib" "$root"
    Copy-Item "$src\lua$v.dll" "$root"
    Copy-Item "$src\lua.exe"   "$root"
    Copy-Item "$src\luac.exe"  "$root"

    foreach ($include in $includes)
    {
        Copy-Item "$src\$include" "$root\include"
    }


    # === Clean up
    Get-Childitem "$lua\" -Recurse | ForEach-Object {
        Remove-Item $_.FullName -Recurse -Force -Confirm:$false
    }
}
else 
{
    Throw "Unknown BuildType $BuildType"
}