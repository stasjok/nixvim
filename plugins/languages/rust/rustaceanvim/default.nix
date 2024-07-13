{
  lib,
  helpers,
  config,
  pkgs,
  ...
}:
with lib;
helpers.neovim-plugin.mkNeovimPlugin config {
  name = "rustaceanvim";
  defaultPackage = pkgs.vimPlugins.rustaceanvim;

  maintainers = [ maintainers.GaetanLepage ];

  # TODO: introduced 2024-05-17, remove on 2024-02-17
  deprecateExtraOptions = true;
  optionsRenamedToSettings = import ./renamed-options.nix;

  extraOptions = {
    rustAnalyzerPackage = helpers.mkPackageOption {
      name = "rust-analyzer";
      default = pkgs.rust-analyzer;
    };
  };

  settingsOptions = import ./settings-options.nix { inherit lib helpers pkgs; };

  settingsExample = {
    server = {
      standalone = false;
      cmd = [
        "rustup"
        "run"
        "nightly"
        "rust-analyzer"
      ];
      default_settings = {
        rust-analyzer = {
          inlayHints = {
            lifetimeElisionHints = {
              enable = "always";
            };
          };
          check = {
            command = "clippy";
          };
        };
      };
    };
  };

  callSetup = false;
  extraConfig =
    cfg:
    let
      configStr = ''
        vim.g.rustaceanvim = ${helpers.toLuaObject cfg.settings}
      '';
    in
    mkMerge [
      {
        extraPackages = [ cfg.rustAnalyzerPackage ];
        # TODO: remove after 24.11
        warnings =
          optional
            (hasAttrByPath [
              "settings"
              "server"
              "settings"
            ] cfg)
            ''
              The `plugins.rustaceanvim.settings.server.settings' option has been renamed to `plugins.rustaceanvim.settings.server.default_settings'.

              Note that if you supplied an attrset and not a function you need to set this attr set in:
                `plugins.rustaceanvim.settings.server.default_settings.rust-analyzer'.
            '';
      }
      # If nvim-lspconfig is enabled:
      (mkIf config.plugins.lsp.enable {
        # Use the same `on_attach` callback as for the other LSP servers
        plugins.rustaceanvim.settings.server.on_attach = mkDefault "__lspOnAttach";

        # Ensure the plugin config is placed **after** the rest of the LSP configuration
        # (and thus after the declaration of `__lspOnAttach`)
        plugins.lsp.postConfig = configStr;
      })
      # Else, just put the plugin config anywhere
      (mkIf (!config.plugins.lsp.enable) { extraConfigLua = configStr; })
    ];
}
