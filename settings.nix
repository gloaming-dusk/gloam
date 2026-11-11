# Gloam Settings: a Lua application that shady-shell draws.
{ runCommand, shady-shell, tide }:

runCommand "gloam-settings" { } ''
  mkdir -p $out/bin $out/share/gloam/settings $out/share/applications
  cp ${./apps/settings/settings.lua} $out/share/gloam/settings/settings.lua
  cat > $out/bin/gloam-settings <<SCRIPT
  #!/bin/sh
  export GLOAM_TIDE=${tide}/share/shady/rices/tide
  exec ${shady-shell}/bin/shady-shell --app $out/share/gloam/settings/settings.lua
  SCRIPT
  chmod +x $out/bin/gloam-settings
  cat > $out/share/applications/gloam-settings.desktop <<ENTRY
  [Desktop Entry]
  Type=Application
  Name=Settings
  Comment=Change how the desktop looks and works
  Exec=$out/bin/gloam-settings
  Categories=Settings;
  ENTRY
''
