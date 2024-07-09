#!/usr/bin/env bash

source $(dirname "$0")/shared.sh

install_arch_basics

local_install openssh
export_install_yay k2pdfopt
local_install kitty-terminfo
export_install_yay d2-bin d2
local_install direnv
local_install dunst
local_install fzf
local_install tldr
local_install zoxide
export_install feh
export_install pulsemixer
export_install restic
export_install unrar
export_install xorg-xset xset
