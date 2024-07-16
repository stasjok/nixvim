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
}
