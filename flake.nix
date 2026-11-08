{
  description = "Gloam, a desktop built on the Shady compositor";

  # Gloam follows the latest NixOS stable release, the same one Shady follows.
  inputs.shady.url = "github:gloaming-dusk/shady";
  inputs.nixpkgs.follows = "shady/nixpkgs";

  outputs = { self, nixpkgs, shady, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          shadyPackage = shady.packages.${system}.default;
        in rec {
          session = pkgs.callPackage ./session.nix { shady = shadyPackage; };
          settings = pkgs.callPackage ./settings.nix { shady = shadyPackage; };
          default = session;
        });

      nixosModules = rec {
        gloam = import ./module.nix { inherit self shady; };
        default = gloam;
      };

      # Builds a whole system with the module, without booting it.
      checks = forAllSystems (system: {
        module = (nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ self.nixosModules.default ./tests/system.nix ];
        }).config.system.build.toplevel;
      });
    };
}
