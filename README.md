# lua
 PowerShell script that downloads and builds the latest Lua or Luau release for Windows.  
 The web with prebuilt binaries has only 5.4.2, while the latest is 5.4.3.  
 This script is mostly only for building, it doesn't set any environment variables etc.

 You must have Visual Studio 2022 installed, preferrably in the default path.  
 If you want to use cl/lib/link that's in a different location, you must edit the script

# Usage
 To build, simply run the `build.ps1 <BuildFor; lua|luau> <BuildConfig; any luau cmake config>` file.  
 If this is not the first time running, clean the previously build files, or clone this repo again.  

 To use in projects, I recommend creating a new system environment variable, eg. `LUADIR`, set to the root path of this repo  
 Now you can add `$(LUADIR)\include` to Additional Include Directories under C++/General,  
 add `$(LUADIR)` to Library Directories under VC++ Directories,  
 and `lua*.lib` to Additional Dependencies under Linker/Input.  
 You should also probably copy the dll (pre-link event `xcopy "$(LUADIR)\lua*.dll" "$(OutDir)" /Y /I`)  

 Luau support is just experimental, but I'll hopefully do something with it some day
