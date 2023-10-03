#!/usr/bin/sh

dir="$HOME/.config/polybar"

launch_bar() {
  killall polybar
  while pgrep polybar; do killall polybar; done
  if [ -f ~/.local/bin/polybar ]
  then
    ~/.local/bin/polybar -q main -c "$dir/config.ini"
  else
    /usr/bin/polybar -q main -c "$dir/config.ini"
  fi
  # TODO add ~/.local/bin to login shell path?
  #polybar -q main -c "$dir/config.ini"
}

launch_bar
