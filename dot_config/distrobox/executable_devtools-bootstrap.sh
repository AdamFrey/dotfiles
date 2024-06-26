#!/usr/bin/env bash

source $(dirname "$0")/shared.sh

#sudo pacman -Syyu
install_arch_basics



export_install ansible ansible-playbook
local_install clang
local_install direnv
#local_install devtools installs a bunch of stuff including pkgctl
local_install fasd
local_install fzf
local_install gdb
local_install git
local_install gtk3
export_install httpie http
# configuring JDK with debug symbols
# https://www.reddit.com/r/archlinux/comments/erct4o/openjdk_debug_symbols/
# https://clojurians.slack.com/archives/C03S1KBA2/p1680889420258109
# https://github.com/async-profiler/async-profiler#installing-debug-symbols
# gdb /usr/lib/jvm/java-17-openjdk/lib/server/libjvm.so -ex 'info address UseG1GC'
local_install fontconfig
local_install jdk17-openjdk
distrobox_export jar
distrobox_export javac
local_install kitty-terminfo
local_install libnotify # gives us notify-send
local_install libxrandr
local_install libxcursor
local_install libxtst # used by nubank morse
local_install libxi
local_install maven
local_install ninja
local_install openssh
local_install podman
local_install rlwrap
local_install tldr
local_install unzip
local_install xapp
local_install zoxide

export_install rustup
distrobox_export cargo
distrobox_export cargo-clippy
distrobox_export cargo-fmt
distrobox_export cargo-miri
distrobox_export clippy-driver
distrobox_export rust-gdb
distrobox_export rust-lldb
distrobox_export rustc
distrobox_export rustdoc
distrobox_export rustfmt

if rustup show | grep -q "stable";
then
    echo "" ## todo remove this
else
    rustup default stable
fi


#export_install_yay async-profiler
export_install chezmoi
local_install clojure
local_install clojure clj
export_install cmake
export_install_yay docker-credential-gcr-bin docker-credential-gcr
export_install_yay flutter
export_install_yay gitu
export_install gradle
local_install imagemagick
export_install_yay koka-bin koka
export_install leiningen lein
export_install mlton # SML compiler
# export_install npm
# distrobox_export node
# distrobox_export npx
export_install jdk17-openjdk java
export_install opam
export_install packer
# export_install pnpm
export_install postgresql psql
export_install shellcheck
export_install smlnj
export_install_yay smlfmt
distrobox_export sqlite3
export_install_yay babashka-bin bb
export_install_yay circleci-cli-bin circleci
export_install_yay cljfmt-bin cljfmt
export_install_yay clj-kondo-bin clj-kondo
export_install_yay flyctl-bin flyctl
export_install_yay temporal-cli temporal
export_install terraform
export_install_yay ucm-bin ucm # Unison Code Manager


yay_i google-cloud-cli gcloud
distrobox_export gcloud /opt/google-cloud-cli/bin/gcloud
distrobox_export gsutil /opt/google-cloud-cli/bin/gsutil
distrobox_export docker-credential-gcloud /opt/google-cloud-cli/bin/docker-credential-gcloud

# curl -L https://fly.io/install.sh | sh


# handled on fedora
#export_install emacs
#export_install emacs emacsclient

export_install ripgrep rg
# For the moment installing from source
# export_install zig zig
# export_install_yay zls-git zls

if [ ! -f ~/.config/gcloud/application_default_credentials.json ]
then
    gcloud auth application-default login
fi
