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
        echo "should install"
    fi
}

lbin=~/.local/bin

export_install() {
    local bin_name="${2:-$1}"
    local_install $1
    distrobox-export --bin /usr/bin/$bin_name --export-path $lbin
}

local_install openssh
local_install kitty-terminfo

export_install direnv
export_install restic
export_install xorg-xset xset
