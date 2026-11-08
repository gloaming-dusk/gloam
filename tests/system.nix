# The smallest system the module can be built into.
{
  programs.gloam.enable = true;
  boot.loader.grub.enable = false;
  fileSystems."/" = { device = "none"; fsType = "tmpfs"; };
  system.stateVersion = "26.05";
}
