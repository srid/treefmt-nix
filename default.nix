# A pure Nix library that handles the treefmt configuration.
let
  # The base module configuration that generates and wraps the treefmt config
  # with Nix.
  module-options = ./module-options.nix;

  # Program to formatter mapping
  programs = import ./programs;

  # Use the Nix module system to validate the treefmt config file format.
  #
  # nixpkgs is an instance of <nixpkgs> that contains treefmt.
  # configuration is an attrset used to configure the nix module
  evalModule = nixpkgs: configuration:
    nixpkgs.lib.evalModules {
      modules = [
        {
          _module.args = {
            pkgs = nixpkgs;
            lib = nixpkgs.lib;
          };
        }
      ]
      ++ optionModules
      ++ [ configuration ];
    };

  # Modules that define the options for treefmt.
  optionModules = [ module-options ] ++ programs.modules;

  # 'options' from all modules gathered in one place.
  mkTreefmtOptions = nixpkgs:
    builtins.foldl'
      (options: mod: nixpkgs.lib.zipAttrsWith (_: vs: nixpkgs.lib.mkMerge vs) [
        options
       (nixpkgs.lib.callPackage mod {}).options
      ])
      { }
      optionModules;

  # Returns a treefmt.toml generated from the passed configuration.
  #
  # nixpkgs is an instance of <nixpkgs> that contains treefmt.
  # configuration is an attrset used to configure the nix module
  mkConfigFile = nixpkgs: configuration:
    let
      mod = evalModule nixpkgs configuration;
    in
    mod.config.build.configFile;

  # Returns an instance of treefmt, wrapped with some configuration.
  #
  # nixpkgs is an instance of <nixpkgs> that contains treefmt.
  # configuration is an attrset used to configure the nix module
  mkWrapper = nixpkgs: configuration:
    let
      mod = evalModule nixpkgs configuration;
    in
    mod.config.build.wrapper;
in
{
  inherit
    module-options
    mkTreefmtOptions
    programs
    evalModule
    mkConfigFile
    mkWrapper
    ;
}
