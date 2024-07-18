{
  nixvim,
  pkgs,
  home-manager,
}:
let
  config = {
    home = {
      username = "nixvim";
      homeDirectory = "/invalid/dir";
      stateVersion = "24.05";
    };

    programs.nixvim = {
      enable = true;

      performance.optimizeRuntimePath.enable = true;

      extraFiles = {
        "test.lua".text = "vim.opt.tabstop = 2";
        # After directory
        "after/test_after.lua".text = "vim.opt.tabstop = 2";
        # File conflicting with plugins
        "doc/lspconfig.txt".text = "*lspconfig.txt*";
        # File in after directory conflicting with plugins
        "after/plugin/cmp_nvim_lsp.lua".text = "require('cmp_nvim_lsp')";
      };

      files."test2.lua".opts.tabstop = 2;

      extraPlugins = with pkgs.vimPlugins; [
        nvim-lspconfig
        cmp-nvim-lsp
      ];

      extraConfigLuaPost = ''
        local function tests()
          -- Nvim internals are working
          vim.lsp.get_clients()

          -- Plugins are loadable
          require("lspconfig")

          -- All user files are available
          local function test_rtp_file(file)
            assert(vim.api.nvim_get_runtime_file(file, false)[1], file .. " isn't found in runtime")
          end
          test_rtp_file("test.lua")
          test_rtp_file("test_after.lua")
          test_rtp_file("test2.lua")

          -- This tests are running with wrapRc = false, so xdg config,
          -- vim-pack-dir and nvim runtime are expected in rtp
          for _, path in ipairs(vim.opt.runtimepath:get()) do
            assert(
              path:find(vim.fn.stdpath("config"), 1, true)
              or path:find("/nvim/runtime", 1, true)
              or path:find("vim-pack-dir", 1, true),
              "unexpected path " .. path .. " found in runtime paths"
            )
          end
          for _, path in ipairs(vim.opt.packpath:get()) do
            assert(
              path:find("/nvim/runtime") or path:find("vim-pack-dir", 1, true),
              "unexpected path " .. path .. " found in packpath"
            )
          end

          -- User files are first in runtimepath
          local lsp_doc_files = vim.api.nvim_get_runtime_file("doc/lspconfig.txt", true)
          assert(#lsp_doc_files == 2, "expected two doc/lspconfig.txt files in runtime")
          assert(
            lsp_doc_files[2]:find("lspconfig/doc/lspconfig.txt", 1, true),
            "first doc/lspconfig.txt in runtime is not from a user config"
          )
          -- User files are last in after directory
          local cmp_lsp_files = vim.api.nvim_get_runtime_file("plugin/cmp_nvim_lsp.lua", true)
          assert(#cmp_lsp_files == 2, "expected two plugin/cmp_nvim_lsp.lua files in runtime")
          assert(
            cmp_lsp_files[1]:find("cmp-nvim-lsp/after", 1, true),
            "after/plugin/cmp_nvim_lsp.lua from a user config is not last"
          )
        end

        -- Run tests
        local ok, msg = pcall(tests)
        if ok then
          vim.cmd("qa!")
        end
        vim.print(msg)
      '';
    };
  };

  homeManagerConfig =
    (home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      modules = [
        nixvim.homeManagerModules.nixvim
        config
      ];
    }).config;
in
pkgs.runCommand "home-manager-optimize-runtime-path" { } ''
  export HOME=$TMPDIR
  export XDG_CONFIG_HOME=${homeManagerConfig.home-files}/.config
  ${homeManagerConfig.home.path}/bin/nvim --headless -c "cq"

  touch $out
''
