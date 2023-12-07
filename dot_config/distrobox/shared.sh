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

yay_i() {
    if ! is_installed $1
    then
        echo "installing $1..."
        yay -S --noconfirm $1
    fi
}

lbin=~/.local/bin

distrobox_export() {
    local executable_path="${2:-/usr/bin/$1}";
    if [ ! -f "$lbin/$1" ]
    then
        distrobox-export --bin "$executable_path" --export-path $lbin
    fi
}

export_install() {
    local bin_name="${2:-$1}"
    local_install $1
    distrobox_export "$bin_name";
}

export_install_yay() {
    local bin_name="${2:-$1}"
    yay_i $1
    distrobox_export "$bin_name";
}


install_yay() {
    if ! is_installed yay
    then
        local_install base-devel
        local_install git
        git clone https://aur.archlinux.org/yay.git ~/.local/share/yay
        cd ~/.local/share/yay
        echo "installing yay..."
        makepkg -si --noconfirm
    fi
}

install_arch_basics () {
    install_yay
    local_install zsh
    local_install neofetch
    yay_i zsh-autosuggestions-git
    yay_i zsh-syntax-highlighting-git
}
