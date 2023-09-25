#!/usr/bin/env bash

source $(dirname "$0")/shared.sh

pacman -Syyu

local_install chezmoi
local_install clojure
local_install direnv
local_install fasd
local_install fzf
local_install git
local_install jdk17-openjdk
local_install kitty-terminfo
local_install leiningen
local_install openssh
local_install rlwrap
local_install tldr

export_install emacs
export_install emacs emacsclient
export_install ripgrep rg

# todo install yay and google cloud sdk
