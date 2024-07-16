{
  config,
  lib,
  helpers,
  pkgs,
  ...
}:
helpers.vim-plugin.mkVimPlugin config {
  name = "fugitive";
  originalName = "vim-fugitive";
  defaultPackage = pkgs.vimPlugins.vim-fugitive;
  extraPackages = [ pkgs.git ];

  maintainers = [ lib.maintainers.GaetanLepage ];

  extraConfig = cfg: {
    # mini.nvim and fugitive have duplicate doc tags
    performance.combinePlugins.standalonePlugins = lib.mkIf (
      config.performance.combinePlugins.enable && config.plugins.mini.enable
    ) [ cfg.package ];
  };

  # In typical tpope fashion, this plugin has no config options
}
