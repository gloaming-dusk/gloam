# Gloam

Gloam is a Wayland desktop. It brings together what is needed to use one all
day, the way GNOME or KDE do:

| | |
|---|---|
| [Shady](https://github.com/gloaming-dusk/shady) | the compositor |
| `shady-shell` and Tide | the desktop shell and its default look |
| `shady-greeter` | the login screen |
| this repository | the session, the services the shell talks to, and the applications |

Gloam used to be a NixOS-based distribution with a live ISO. It is a desktop
you add to a system now.

## Installing on NixOS

```nix
{
  inputs.gloam.url = "github:gloaming-dusk/gloam";

  outputs = { nixpkgs, gloam, ... }: {
    nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        gloam.nixosModules.default
        { programs.gloam.enable = true; }
      ];
    };
  };
}
```

This turns on the Shady session and its login screen, NetworkManager, PipeWire,
Bluetooth, power profiles, a polkit agent and a keyring, and installs the
applications in `programs.gloam.apps`, which you can replace. Every
`programs.shady` option still applies.

To change the desktop itself, see
[Customizing](https://gloaming-dusk.github.io/docs/customizing/).

## Applications

Gloam uses good existing applications where it can: Nautilus, Loupe, Papers,
Text Editor, Calculator, Celluloid and Firefox. It has its own only where nothing
else can do the job:

- **Settings** (`gloam-settings`, also from the control center): the accent
  colour, wallpaper, window corners and gaps, keyboard and touchpad. It is
  drawn the way the shell is (`shady-shell --app`, `apps/settings/settings.lua`)
  and saves to `~/.config/shady/settings.lua`. Changes apply at once.

## Checking

```sh
nix build .#checks.x86_64-linux.module
```

This builds a whole system with the module, without booting it.
