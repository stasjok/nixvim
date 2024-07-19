{ pkgs, helpers, ... }:
{
  default = {
    performance.optimizeRuntimePath.enable = true;

    extraFiles = {
      "test.lua".text = "vim.opt.tabstop = 2";
      # After directory
      "after/test_after.lua".text = "vim.opt.tabstop = 2";
    };

    files."test2.lua".opts.tabstop = 2;

    extraPlugins = [ pkgs.vimPlugins.nvim-lspconfig ];

    extraConfigLuaPost = ''
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

      -- This tests are running with wrapRc = true,
      -- so only vim-pack-dir and nvim runtime are expected in rtp
      for _, path in ipairs(vim.opt.runtimepath:get()) do
        assert(
          path:find("/nvim/runtime") or path:find("vim-pack-dir", 1, true),
          "unexpected path " .. path .. " found in runtime paths"
        )
      end
      for _, path in ipairs(vim.opt.packpath:get()) do
        assert(
          path:find("/nvim/runtime") or path:find("vim-pack-dir", 1, true),
          "unexpected path " .. path .. " found in packpath"
        )
      end
    '';
  };

  disabled = {
    performance.optimizeRuntimePath.enable = false;

    extraFiles = {
      "test.lua".text = "vim.opt.tabstop = 2";
      # After directory
      "after/test_after.lua".text = "vim.opt.tabstop = 2";
    };

    files."test2.lua".opts.tabstop = 2;

    extraPlugins = [ pkgs.vimPlugins.nvim-lspconfig ];

    extraConfigLuaPost = ''
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
    '';
  };

  extra-paths = {
    performance.optimizeRuntimePath = {
      enable = true;

      extraRuntimePaths = [
        # By derivation
        (pkgs.writeTextDir "/rtp.txt" "1")
        # By string
        (toString (pkgs.writeTextDir "/rtp.txt" "2"))
        # By raw lua
        (helpers.mkRaw "string.format('${pkgs.writeTextDir "/rtp.txt" "3"}')")
        # After directories
        (pkgs.writeTextDir "/after/rtp.txt" "after3")
        (pkgs.writeTextDir "/after/rtp.txt" "after2")
        (pkgs.writeTextDir "/after/rtp.txt" "after1")
      ];

      extraPackPaths = [
        # By derivation
        (pkgs.writeTextDir "/pack/test/start/test/pack.txt" "1")
        # By string
        (toString (pkgs.writeTextDir "/pack/test/start/test/pack.txt" "2"))
        # By raw lua
        (helpers.mkRaw "string.format('${pkgs.writeTextDir "/pack/test/start/test/pack.txt" "3"}')")
      ];
    };

    extraFiles = {
      # Not testing home files for now, because they are placed as a plugin in vim-pack-dir
      # So order will be wrong (user files should be before any other paths,
      # but in practice they are last)
      # "rtp.txt".text = "1";
      # "after/rtp.txt".text = "after4";
    };

    extraConfigLuaPre = ''
      local rtp_files = vim.api.nvim_get_runtime_file("rtp.txt", true)
      assert(#rtp_files == 6, "wrong number of rtp.txt files in runtime")

      local pack_files = vim.api.nvim_get_runtime_file("pack.txt", true)
      assert(#pack_files == 3, "wrong number of pack.txt files in runtime")

      -- Test order
      for i = 1, 3 do
        -- Rtp dirs
        assert(vim.fn.readfile(rtp_files[i])[1] == tostring(i), "wrong order of rtp files")
        -- After directories are reversed, so first found (number 5) is from plugin, others from rtp
        assert(vim.fn.readfile(rtp_files[i+3])[1] == "after" .. i, "wrong order of 'after' rtp files")
        -- Pack dirs
        assert(vim.fn.readfile(pack_files[i])[1] == tostring(i), "wrong order of pack files")
      end
    '';
  };
}
