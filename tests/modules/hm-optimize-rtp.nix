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

      performance.optimizeRuntimePath = {
        enable = true;
        extraRuntimePaths = [
          (pkgs.writeTextDir "/rtp.txt" "2")
          (pkgs.writeTextDir "/rtp.txt" "3")
          (pkgs.writeTextDir "/rtp.txt" "4")
          # After directories
          (pkgs.writeTextDir "/after/rtp.txt" "after3")
          (pkgs.writeTextDir "/after/rtp.txt" "after2")
          (pkgs.writeTextDir "/after/rtp.txt" "after1")
        ];
        extraPackPaths = [
          (pkgs.writeTextDir "/pack/test/start/test/pack.txt" "1")
          (pkgs.writeTextDir "/pack/test/start/test/pack.txt" "2")
          (pkgs.writeTextDir "/pack/test/start/test/pack.txt" "3")
          (pkgs.writeTextDir "/pack/test/start/test/pack.txt" "4")
        ];
      };

      extraFiles = {
        "test.lua".text = "vim.opt.tabstop = 2";
        # After directory
        "after/test_after.lua".text = "vim.opt.tabstop = 2";
        # File conflicting with plugins
        "doc/lspconfig.txt".text = "*lspconfig.txt*";
        # File in after directory conflicting with plugins
        "after/plugin/cmp_nvim_lsp.lua".text = "require('cmp_nvim_lsp')";

        "rtp.txt".text = "1";
        "after/rtp.txt".text = "after4";
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
          -- vim-pack-dir, nvim runtime and extraRuntimePaths are expected in rtp
          for _, path in ipairs(vim.opt.runtimepath:get()) do
            assert(
              path:find(vim.fn.stdpath("config"), 1, true)
              or path:find("/nvim/runtime", 1, true)
              or path:find("vim-pack-dir", 1, true)
              or path:find("-rtp.txt", 1, true),
              "unexpected path " .. path .. " found in runtime paths"
            )
          end
          for _, path in ipairs(vim.opt.packpath:get()) do
            assert(
              path:find("/nvim/runtime")
              or path:find("vim-pack-dir", 1, true)
              or path:find("-pack.txt", 1, true),
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

          local rtp_files = vim.api.nvim_get_runtime_file("rtp.txt", true)
          assert(#rtp_files == 8, "wrong number of rtp.txt files in runtime")

          local pack_files = vim.api.nvim_get_runtime_file("pack.txt", true)
          assert(#pack_files == 4, "wrong number of pack.txt files in runtime")

          -- Test order
          for i = 1, 4 do
            -- Rtp dirs
            assert(vim.fn.readfile(rtp_files[i])[1] == tostring(i), "wrong order of rtp files")
            -- After directories are reversed, so first found (number 5) is from plugin, others from rtp
            assert(vim.fn.readfile(rtp_files[i+4])[1] == "after" .. i, "wrong order of 'after' rtp files")
            -- Pack dirs
            assert(vim.fn.readfile(pack_files[i])[1] == tostring(i), "wrong order of pack files")
          end
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
