# NixOS module: `programs.gloam.enable = true;` installs the Gloam desktop.
{ self, shady, shady-shell, shady-greeter }:
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.gloam;
  system = pkgs.stdenv.hostPlatform.system;
  session = self.packages.${system}.session;
  desktop = app: "${app}.desktop";
in
{
  imports = [
    shady.nixosModules.default
    shady-shell.nixosModules.default
    shady-greeter.nixosModules.default
  ];

  options.programs.gloam = {
    enable = lib.mkEnableOption "the Gloam desktop";

    apps = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        firefox
        nautilus
        loupe
        papers
        gnome-text-editor
        gnome-calculator
        celluloid
      ];
      defaultText = lib.literalExpression
        "with pkgs; [ firefox nautilus loupe papers gnome-text-editor gnome-calculator celluloid ]";
      description = "The applications installed with the desktop.";
    };
  };

  config = lib.mkIf cfg.enable {
    # The compositor, Tide's shell over its compositor side, and the
    # login screen.
    programs.shady.enable = true;
    programs.shady.rices = [ self.packages.${system}.tide ];
    programs.shady-shell.enable = true;
    services.shady-greeter.enable = lib.mkDefault true;
    services.shady-greeter.softwareCursor = lib.mkDefault config.programs.shady.softwareCursor;
    services.displayManager.sessionPackages = [ session ];

    # What the shell's control center and the applications talk to.
    networking.networkmanager.enable = lib.mkDefault true;
    services.pipewire = {
      enable = lib.mkDefault true;
      pulse.enable = lib.mkDefault true;
    };
    hardware.bluetooth.enable = lib.mkDefault true;
    services.upower.enable = lib.mkDefault true;
    services.power-profiles-daemon.enable = lib.mkDefault true;
    services.gvfs.enable = lib.mkDefault true;
    services.gnome.gnome-keyring.enable = lib.mkDefault true;

    systemd.user.services.gloam-polkit-agent = {
      description = "Gloam's authentication agent";
      wantedBy = [ "shady-session.target" ];
      partOf = [ "shady-session.target" ];
      after = [ "shady-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
      };
    };

    fonts.packages = with pkgs; [ noto-fonts noto-fonts-cjk-sans noto-fonts-color-emoji ];

    environment.systemPackages = [ self.packages.${system}.settings ]
      ++ cfg.apps ++ (with pkgs; [ brightnessctl pavucontrol ]);

    xdg.mime.defaultApplications = {
      "inode/directory" = desktop "org.gnome.Nautilus";
      "application/pdf" = desktop "org.gnome.Papers";
      "text/plain" = desktop "org.gnome.TextEditor";
      "image/png" = desktop "org.gnome.Loupe";
      "image/jpeg" = desktop "org.gnome.Loupe";
      "image/webp" = desktop "org.gnome.Loupe";
      "video/mp4" = desktop "io.github.celluloid_player.Celluloid";
      "video/x-matroska" = desktop "io.github.celluloid_player.Celluloid";
      "text/html" = desktop "firefox";
      "x-scheme-handler/http" = desktop "firefox";
      "x-scheme-handler/https" = desktop "firefox";
    };
  };
}
