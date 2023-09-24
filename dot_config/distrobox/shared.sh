#!/usr/bin/env bash

is_installed() {
    if pacman -Qi $1 > /dev/null
    then
        return 0
    else
        return 1
    fi
}

local_install() {
    if ! is_installed $1
    then
        echo "installing $1..."
        sudo pacman -S --noconfirm $1

    fi
}

lbin=~/.local/bin

export_install() {
    local bin_name="${2:-$1}"
    local_install $1
    distrobox-export --bin /usr/bin/$bin_name --export-path $lbin
}
