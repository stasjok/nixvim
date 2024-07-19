{ lib, helpers, ... }:
let
  inherit (lib) types;
in
{
  options.performance = {
    optimizeRuntimePath = {
      enable = lib.mkEnableOption ''
        runtime search path optimization. It sets `runtimepath`
        and `packpath` options to the minimum list of essential paths'';
      extraRuntimePaths = lib.mkOption {
        description = "Extra paths to add to `runtimepath`.";
        type = with helpers.nixvimTypes; listOf (maybeRaw path);
        default = [ ];
        example = [ (helpers.mkRaw "vim.fs.joinpath(vim.fn.stdpath('data'), 'site')") ];
      };
      extraPackPaths = lib.mkOption {
        description = "Extra paths to add to `packpath`.";
        type = with helpers.nixvimTypes; listOf (maybeRaw path);
        default = [ ];
        example = [ (helpers.mkRaw "vim.fs.joinpath(vim.fn.stdpath('data'), 'site')") ];
      };
    };

    combinePlugins = {
      enable = lib.mkEnableOption "combinePlugins" // {
        description = ''
          Whether to enable EXPERIMENTAL option to combine all plugins
          into a single plugin pack. It can significantly reduce startup time,
          but all your plugins must have unique filenames and doc tags.
          Any collision will result in a build failure. To avoid collisions
          you can add your plugin to the `standalonePlugins` option.
          Only standard neovim runtime directories are linked to the combined plugin.
          If some of your plugins contain important files outside of standard
          directories, add these paths to `pathsToLink` option.
        '';
      };
      pathsToLink = lib.mkOption {
        type = with types; listOf str;
        default = [ ];
        example = [ "/data" ];
        description = "List of paths to link into a combined plugin pack.";
      };
      standalonePlugins = lib.mkOption {
        type = with types; listOf (either str package);
        default = [ ];
        example = [ "nvim-treesitter" ];
        description = "List of plugins (names or packages) to exclude from plugin pack.";
      };
    };

    byteCompileLua = {
      enable = lib.mkEnableOption "byte compiling of lua files";
      initLua = lib.mkEnableOption "initLua" // {
        description = "Whether to byte compile init.lua.";
        default = true;
      };
      configs = lib.mkEnableOption "configs" // {
        description = "Whether to byte compile lua configuration files.";
        default = true;
      };
      plugins = lib.mkEnableOption "plugins" // {
        description = "Whether to byte compile lua plugins.";
      };
      nvimRuntime = lib.mkEnableOption "nvimRuntime" // {
        description = "Whether to byte compile lua files in Nvim runtime.";
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
      # plenary.nvim
      "/data/plenary/filetypes"
    ];
  };
}
