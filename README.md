# Dotfiles

Powered by Chezmoi

## Instructions

``` commands
chezmoi init
# Web Browser Application? flatpak run org.mozilla.firefox
# Text Editor Application? emacsclient --create-frame --no-wait --socket-name=adam-emacsd

chezmoi init --prompt    # if you need to re-set the variables

bootstrap-system         # set up machine, or re-sync
bootstrap-system --noweb # set up machine without web flatpaks, or remove them 
dtt                      # enter into the devtools distrobox 
```


## Distrobox

Commands to sync distroboxes

``` sh
distrobox-enter -n devtools -e ~/.config/distrobox/devtools-bootstrap.sh
distrobox-enter -n desktop-tools -e ~/.config/distrobox/desktop-tools-bootstrap.sh
```

