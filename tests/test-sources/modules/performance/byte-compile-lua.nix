{ pkgs, helpers, ... }:
let
  isByteCompiledFun = ''
    local function is_byte_compiled(filename)
      local f = assert(io.open(filename, "rb"))
      local data = assert(f:read("*a"))
      -- Assume that file is binary if it contains null bytes
      for i = 1, #data do
        if data:byte(i) == 0 then
          return true
        end
      end
      return false
    end

    local function test_rtp_file(name, is_compiled)
      local file = assert(vim.api.nvim_get_runtime_file(name, false)[1], "file " .. name .. " not found in runtime")
      if is_compiled then
        assert(is_byte_compiled(file), name .. " is expected to be byte compiled, but it's not")
      else
        assert(not is_byte_compiled(file), name .. " is not expected to be byte compiled, but it is")
      end
    end
  '';
in
{
  default = {
    performance.byteCompileLua.enable = true;

    extraFiles = {
      "plugin/file_text.lua".text = "vim.opt.tabstop = 2";
      "plugin/file_source.lua".source = helpers.writeLua "file_source.lua" "vim.opt.tabstop = 2";
      "plugin/test.vim".text = "set tabstop=2";
      "plugin/test.json".text = builtins.toJSON { a = 1; };
    };

    files = {
      "plugin/file.lua" = {
        opts.tabstop = 2;
      };
      "plugin/file.vim" = {
        opts.tabstop = 2;
      };
    };

    extraPlugins = [ pkgs.vimPlugins.nvim-lspconfig ];

    extraConfigLuaPost = ''
      ${isByteCompiledFun}

      -- vimrc is byte compiled
      local init = vim.env.MYVIMRC or vim.fn.getscriptinfo({name = "init.lua"})[1].name
      assert(is_byte_compiled(init), "MYVIMRC is expected to be byte compiled, but it's not")

      -- nixvim-print-init prints text
      local init_content = vim.fn.system("nixvim-print-init")
      -- Search this string in nixvim-print-init output: VALIDATING_STRING
      assert(init_content:find("VALIDATING_" .. "STRING"), "nixvim-print-init's output is byte compiled")

      -- extraFiles
      test_rtp_file("plugin/file_text.lua", true)
      test_rtp_file("plugin/file_source.lua", true)
      test_rtp_file("plugin/test.vim", false)
      test_rtp_file("plugin/test.json", false)

      -- files
      test_rtp_file("plugin/file.lua", true)
      test_rtp_file("plugin/file.vim", false)

      -- Plugins and neovim runtime aren't byte compiled by default
      test_rtp_file("lua/vim/lsp.lua", false)
      test_rtp_file("lua/lspconfig.lua", false)
    '';
  };

  disabled = {
    performance.byteCompileLua.enable = false;

    extraFiles."plugin/test1.lua".text = "vim.opt.tabstop = 2";

    files."plugin/test2.lua".opts.tabstop = 2;

    extraPlugins = [ pkgs.vimPlugins.nvim-lspconfig ];

    extraConfigLuaPost = ''
      ${isByteCompiledFun}

      -- vimrc
      local init = vim.env.MYVIMRC or vim.fn.getscriptinfo({name = "init.lua"})[1].name
      assert(not is_byte_compiled(init), "MYVIMRC is not expected to be byte compiled, but it is")

      -- nixvim-print-init prints text
      local init_content = vim.fn.system("nixvim-print-init")
      -- Search this string in nixvim-print-init output: VALIDATING_STRING
      assert(init_content:find("VALIDATING_" .. "STRING"), "nixvim-print-init's output is byte compiled")

      -- Nothing is byte compiled
      -- extraFiles
      test_rtp_file("plugin/test1.lua", false)
      -- files
      test_rtp_file("plugin/test2.lua", false)
      -- Plugins
      test_rtp_file("lua/lspconfig.lua", false)
      -- Neovim runtime
      test_rtp_file("lua/vim/lsp.lua", false)
    '';
  };

  init-lua-disabled = {
    performance.byteCompileLua = {
      enable = true;
      initLua = false;
    };

    extraConfigLuaPost = ''
      ${isByteCompiledFun}

      -- vimrc is not byte compiled
      local init = vim.env.MYVIMRC or vim.fn.getscriptinfo({name = "init.lua"})[1].name
      assert(not is_byte_compiled(init), "MYVIMRC is not expected to be byte compiled, but it is")
    '';
  };

  configs-disabled = {
    performance.byteCompileLua = {
      enable = true;
      configs = false;
    };

    extraFiles."plugin/test1.lua".text = "vim.opt.tabstop = 2";

    files."plugin/test2.lua".opts.tabstop = 2;

    extraConfigLuaPost = ''
      ${isByteCompiledFun}

      -- extraFiles
      test_rtp_file("plugin/test1.lua", false)
      -- files
      test_rtp_file("plugin/test2.lua", false)
    '';
  };

  nvim-runtime = {
    performance.byteCompileLua = {
      enable = true;
      nvimRuntime = true;
    };

    extraPlugins = [
      # Python 3 dependencies
      (pkgs.vimPlugins.nvim-lspconfig.overrideAttrs { passthru.python3Dependencies = ps: [ ps.pyyaml ]; })
    ];

    extraConfigLuaPost = ''
      ${isByteCompiledFun}

      -- vim namespace is working
      vim.opt.tabstop = 2
      vim.api.nvim_get_runtime_file("init.lua", false)
      vim.lsp.get_clients()
      vim.treesitter.language.get_filetypes("nix")
      vim.iter({})

      test_rtp_file("lua/vim/lsp.lua", true)
      test_rtp_file("lua/vim/iter.lua", true)
      test_rtp_file("lua/vim/treesitter/query.lua", true)
      test_rtp_file("lua/vim/lsp/buf.lua", true)
      test_rtp_file("plugin/editorconfig.lua", true)
      test_rtp_file("plugin/tutor.vim", false)
      test_rtp_file("ftplugin/vim.vim", false)

      -- Python3 packages are importable
      vim.cmd.py3("import yaml")
    '';
  };
}
//
  # Two equal tests, one with combinePlugins.enable = true
  pkgs.lib.genAttrs
    [
      "plugins"
      "plugins-combined"
    ]
    (name: {
      performance = {
        byteCompileLua = {
          enable = true;
          plugins = true;
        };

        combinePlugins.enable = pkgs.lib.hasSuffix "combined" name;
      };

      extraPlugins = with pkgs.vimPlugins; [
        nvim-lspconfig
        # Depends on plenary-nvim
        telescope-nvim
        # buildCommand plugin with python3 dependency
        ((pkgs.writeTextDir "/plugin/test.lua" "vim.opt.tabstop = 2").overrideAttrs {
          passthru.python3Dependencies = ps: [ ps.pyyaml ];
        })
        # Plugin with invalid lua file tests/indent/lua/cond.lua (should be ignored)
        nvim-treesitter
      ];

      extraConfigLuaPost = ''
        ${isByteCompiledFun}

        -- Plugins are loadable
        require("lspconfig")
        require("telescope")
        require("plenary")
        require("nvim-treesitter")

        -- Python modules are importable
        vim.cmd.py3("import yaml")

        -- nvim-lspconfig
        test_rtp_file("lua/lspconfig.lua", true)
        test_rtp_file("lua/lspconfig/server_configurations/nixd.lua", true)
        test_rtp_file("plugin/lspconfig.lua", true)
        test_rtp_file("doc/lspconfig.txt", false)

        -- telescope-nvim
        test_rtp_file("lua/telescope/init.lua", true)
        test_rtp_file("lua/telescope/builtin/init.lua", true)
        test_rtp_file("plugin/telescope.lua", true)
        test_rtp_file("autoload/health/telescope.vim", false)
        test_rtp_file("doc/telescope.txt", false)

        -- Dependency of telescope-nvim (plenary-nvim)
        test_rtp_file("lua/plenary/init.lua", true)
        test_rtp_file("plugin/plenary.vim", false)

        -- Test plugin
        test_rtp_file("plugin/test.lua", true)

        -- nvim-treesitter
        test_rtp_file("lua/nvim-treesitter/health.lua", true)
        test_rtp_file("lua/nvim-treesitter/install.lua", true)
        test_rtp_file("plugin/nvim-treesitter.lua", true)
        test_rtp_file("queries/nix/highlights.scm", false)
      '';
    })
