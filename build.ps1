# Copyright (c) 2022 spejik
# Currently supported Lua version: 5.4.4
# https://www.lua.org/download.html (for checksum)
Param (
)

$ver = "5.4.4"
$v = "544"
$checksum = "03c27684b9d5d9783fb79a7c836ba1cdc5f309cd"


$root = $PSScriptRoot
$lua = "$root\lua-$ver"
$src = "$lua\src"


# TODO: maybe there's a better way to find these files?
# Right now we have to use where.exe cl/link/lib in the VS developer console and enter them manually
$vsdir = "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.30.30705\bin\Hostx64\x64"
$vc = "call ""C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"" &&"
$cl = "$vc ""$vsdir\cl.exe"""
$link = "$vc ""$vsdir\link.exe"""
$lib = "$vc ""$vsdir\lib.exe"""


# === Download
# Download tar (pipe to null for sync)
(New-Object System.Net.WebClient).DownloadFile("https://www.lua.org/ftp/lua-$ver.tar.gz", "$root\lua-$ver.tar.gz") | Out-Null
# Validate
if ((Get-FileHash -Algorithm SHA1 "$root\lua-$ver.tar.gz").Hash -ne $checksum)
{
    Throw "Downloaded file does not match checksum"
}
# tar.exe comes with WSL
cmd.exe /c "tar -xzf $root\lua-$ver.tar.gz" | Out-Null


# === Build
Set-Location $src
# Create output directories
New-Item -Path $root -Name "include" -ItemType "directory" -ErrorAction Ignore

# Build object files
cmd.exe /c "$cl /MD /O2 /Ot /c /DLUA_BUILD_AS_DLL *.c" | Out-Null

# Rename the exe objects, so they don't disrupt the next step
Rename-Item lua.obj lua.o
Rename-Item luac.obj luac.o

# Link libraries and executables
cmd.exe /c "$link /DLL /IMPLIB:lua$v.lib /OUT:lua$v.dll *.obj" | Out-Null # lua.dll (dynamic)
cmd.exe /c "$link /OUT:lua.exe lua.o lua$v.lib"                | Out-Null # lua.exe
cmd.exe /c "$lib /OUT:lua$v.lib *.obj"                         | Out-Null # lua.lib (static)
cmd.exe /c "$link /OUT:luac.exe luac.o lua$v.lib"              | Out-Null # luac.exe
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
Remove-Item -LiteralPath "$lua\" -Force -Recurse -Confirm:$false
Remove-Item "$root\lua-$ver.tar.gz"
