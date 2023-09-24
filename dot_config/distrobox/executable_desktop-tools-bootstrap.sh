#!/usr/bin/env bash

source $(dirname "$0")/shared.sh

local_install openssh
local_install kitty-terminfo

export_install direnv
export_install restic
export_install xorg-xset xset
