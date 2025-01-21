{ pkgs, lib, config, inputs, ... }:

{
  languages.python = {
    enable = true;
    venv.enable = true;
    venv.requirements = ''
      beets
      beetcamp
    '';
  };
}
