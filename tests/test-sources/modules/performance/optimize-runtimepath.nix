{ pkgs, ... }:
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
}
