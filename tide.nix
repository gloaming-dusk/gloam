# Tide's shell side: shell.lua, its style, fonts and sea, in the rice
# directory where Shady's part of Tide (config.lua, init.lua) also lives
# once both are installed (share/shady/rices/tide).
{ runCommand }:

runCommand "gloam-tide" { } ''
  dest=$out/share/shady/rices/tide
  mkdir -p $dest
  cp -r ${./rices/tide/shell.lua} $dest/shell.lua
  cp -r ${./rices/tide/style.lua} $dest/style.lua
  # The same loader as Shady's; shell.lua reads it from beside itself.
  cp -r ${./rices/tide/settings.lua} $dest/settings.lua
  cp -r ${./rices/tide/fonts} $dest/fonts
  cp -r ${./rices/tide/shaders} $dest/shaders
''
