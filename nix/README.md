# NixOS Flake Configuration

## First time


``` sh
cp /etc/nixos/hardware-configuration.nix machines/device-name-hardware-configuration.nix
cp example-machine.nix machines/device-name.nix

```

Then edit `flake.nix` to add new machine.

```sh
sudo nixos-rebuild switch --flake .#device-name
```

Edit `x-os-rebuild` script with hostname -> device name mapping

Run `x-os-rebuild` and make sure that ~/.config/emacs is a copy of the
doom-emacs repo.

Run `~/.config/emacs/bin/doom install`

## Updates

``` sh
x-os-rebuild
```



