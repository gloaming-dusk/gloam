# Gloam

Gloam is a Wayland desktop. It brings together what is needed to use one all
day, the way GNOME or KDE do:

| | |
|---|---|
| [Shady](https://github.com/gloaming-dusk/shady) | the compositor, and Tide's layout, keys and rules |
| [shady-shell](https://github.com/gloaming-dusk/shady-shell) | the desktop shell |
| [shady-greeter](https://github.com/gloaming-dusk/shady-greeter) | the login screen |
| this repository | Tide's shell (`rices/tide`: the bar, control center, launcher, lock screen), the session, the services the shell talks to, and the applications |

## Trying it

```sh
nix run github:gloaming-dusk/gloam
```

opens the desktop in a window of your current Wayland session (or full
screen on a text console), with a terminal.

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

This turns on the Shady session with shady-shell and Tide, the login
screen, NetworkManager, PipeWire, Bluetooth, power profiles, a polkit agent
and a keyring, and installs the applications in `programs.gloam.apps`, which
you can replace. Every `programs.shady`, `programs.shady-shell` and
`services.shady-greeter` option still applies.

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

## Tide

Tide is in two parts that meet in `share/shady/rices/tide`: Shady has its
compositor side (`config.lua`, `init.lua`), and this repository its shell
(`rices/tide/shell.lua`, `style.lua`, the fonts and the sea shader), packaged as
`.#tide`. Shady works without this part: Tide's keys then fall back on what
the compositor can do alone.

## Checking

```sh
nix build .#checks.x86_64-linux.module
```

This builds a whole system with the module, without booting it.

```sh
nix develop ../shady -c tests/run.sh
```

runs Tide's headless tests (the default desktop, configs built on it,
`shady-rice eject`, the screenshot picker, the launcher with an input method)
against a built Shady checkout (`SHADY_CHECKOUT`, default `../shady`) and
shady-shell (`SHADY_SHELL_BIN`, default `../shady-shell/build/shady-shell`).
