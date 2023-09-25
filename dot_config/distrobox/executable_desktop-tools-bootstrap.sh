#!/usr/bin/env bash

source $(dirname "$0")/shared.sh

install_arch_basics

local_install openssh
local_install kitty-terminfo

export_install direnv
export_install restic
export_install xorg-xset xset
export_install fasd
export_install fzf
export_install tldr

yay_i ttf-icomoon-feather-git
# TODO copy from container
#  /usr/share/fonts/TTF/icomoon-feather.ttf
# to ~/.local/share/fonts/ ?
