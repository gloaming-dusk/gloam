{
  description = "Gloam, a NixOS-based distribution built around the Shady 3D compositor";

  # Gloam follows the latest NixOS stable release, the same one Shady follows.
  inputs.shady.url = "github:gloaming-dusk/shady";
  inputs.nixpkgs.follows = "shady/nixpkgs";

  outputs = { self, nixpkgs, shady, ... }: {
    nixosConfigurations.gloam-live = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ (import ./iso.nix shady) ];
    };
  };
}
