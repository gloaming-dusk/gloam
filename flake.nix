{
  description = "Gloam, a desktop built on the Shady compositor";

  # Gloam follows the latest NixOS stable release, the same one Shady follows.
  inputs.shady.url = "github:gloaming-dusk/shady";
  inputs.nixpkgs.follows = "shady/nixpkgs";
  inputs.shady-shell.url = "github:gloaming-dusk/shady-shell";
  inputs.shady-shell.inputs.nixpkgs.follows = "shady/nixpkgs";
  inputs.shady-shell.inputs.shady.follows = "shady";
  inputs.shady-greeter.url = "github:gloaming-dusk/shady-greeter";
  inputs.shady-greeter.inputs.nixpkgs.follows = "shady/nixpkgs";
  inputs.shady-greeter.inputs.shady.follows = "shady";
  inputs.shady-greeter.inputs.shady-shell.follows = "shady-shell";

  outputs = { self, nixpkgs, shady, shady-shell, shady-greeter, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          shadyPackage = shady.packages.${system}.default;
          shellPackage = shady-shell.packages.${system}.default;
        in rec {
          session = pkgs.callPackage ./session.nix { shady = shadyPackage; };
          settings = pkgs.callPackage ./settings.nix { shady-shell = shellPackage; inherit tide; };
          tide = pkgs.callPackage ./tide.nix { };
          default = session;
        });

      # `nix run github:gloaming-dusk/gloam`: the desktop in a window of the
      # current Wayland session (or on a VT), with a terminal.
      apps = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          compositor = shady.packages.${system}.default;
          shell = shady-shell.packages.${system}.default;
          try = pkgs.writeShellScript "gloam-try" ''
            export SHADY_SESSION_LOG=stderr
            export SHADY_RICE_PATH=${self.packages.${system}.tide}/share/shady/rices''${SHADY_RICE_PATH:+:$SHADY_RICE_PATH}
            export PATH=${self.packages.${system}.settings}/bin:$PATH
            export SHADY_SHELL_BIN=${shell}/bin/shady-shell
            export SHADY_STARTUP="${shell}/bin/shady-shell & exec ${pkgs.foot}/bin/foot"
            exec ${compositor}/bin/shady-session "$@"
          '';
        in {
          default = { type = "app"; program = "${try}"; };
        });

      nixosModules = rec {
        gloam = import ./module.nix { inherit self shady shady-shell shady-greeter; };
        default = gloam;
      };

      # `nix develop`: what tests/run.sh needs besides a built Shady checkout.
      # The tests type with wtype, take pictures with grim, copy with
      # wl-copy and give the shell its own bus with dbus-run-session.
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [ wtype grim wl-clipboard dbus ];
          };
        });

      # Builds a whole system with the module, without booting it.
      checks = forAllSystems (system: {
        module = (nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ self.nixosModules.default ./tests/system.nix ];
        }).config.system.build.toplevel;
      });
    };
}
