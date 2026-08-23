# SQLite, including the native shared library.
#
# `pkgs.sqlite` is a multi-output derivation, and dropping it into
# systemPackages only installs the `bin` output: you get the `sqlite3` CLI but
# no libsqlite3.so anywhere the dynamic linker will look.
#
# So this package installs the `out` output too, and puts it on LD_LIBRARY_PATH.
#
# Optional module -- add ./sqlite.nix to a machine's extraModules in flake.nix.
{ lib, pkgs, ... }:

let
  sqliteLib = lib.getLib pkgs.sqlite; # the `out` output, holds lib/libsqlite3.so{,.0}
in
{
  environment.systemPackages = [
    pkgs.sqlite # sqlite3 CLI
    sqliteLib   # libsqlite3.so* -> /run/current-system/sw/lib
  ];

  environment.sessionVariables.LD_LIBRARY_PATH = [ "${sqliteLib}/lib" ];
}
