# The "Gloam" entry in the login screen's list of sessions.
{ writeTextFile, shady }:

(writeTextFile {
  name = "gloam-session";
  destination = "/share/wayland-sessions/gloam.desktop";
  text = ''
    [Desktop Entry]
    Name=Gloam
    Comment=An everyday desktop on the Shady compositor
    Exec=${shady}/bin/shady-session
    Type=Application
    DesktopNames=shady
  '';
}) // { providedSessions = [ "gloam" ]; }
