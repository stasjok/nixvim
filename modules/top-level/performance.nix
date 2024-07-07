{ lib, ... }:
let
  inherit (lib) types;
in
{
  options.performance = {
    combinePlugins = {
      enable = lib.mkEnableOption "combinePlugins";
      pathsToLink = lib.mkOption {
        type = with types; listOf str;
        default = [ ];
        description = "List of paths to link to combined plugin pack.";
      };
    };
  };

  config.performance = {
    # Set option value with default priority so that values are appended by default
    combinePlugins.pathsToLink = [
      # :h rtp
      "/autoload"
      "/colors"
      "/compiler"
      "/doc"
      "/ftplugin"
      "/indent"
      "/keymap"
      "/lang"
      "/lua"
      "/pack"
      "/parser"
      "/plugin"
      "/queries"
      "/rplugin"
      "/spell"
      "/syntax"
      "/tutor"
      "/after"
      # ftdetect
      "/ftdetect"
    ];
  };
}
