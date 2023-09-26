#!/usr/bin/sh

dir="$HOME/.config/polybar"

launch_bar() {
  killall polybar
  while pgrep polybar; do killall polybar; done
  ~/.local/bin/polybar -q main -c "$dir/config.ini"
  # TODO add ~/.local/bin to login shell path?
  #polybar -q main -c "$dir/config.ini"
}

launch_bar
