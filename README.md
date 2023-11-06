# Dotfiles

Powered by Chezmoi

## Distrobox

Commands to sync distroboxes

``` sh
distrobox-enter -n devtools -e ~/.config/distrobox/devtools-bootstrap.sh
distrobox-enter -n desktop-tools -e ~/.config/distrobox/desktop-tools-bootstrap.sh
```

## Instructions

``` commands
bootstrap-system         # set up machine, or re-sync
bootstrap-system --noweb # set up machine without web flatpaks, or remove them 
dtt                      # enter into the devtools distrobox 
```
