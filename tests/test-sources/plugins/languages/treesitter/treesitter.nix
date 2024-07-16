{ pkgs, ... }:
{
  default = {
    plugins.treesitter = {
      enable = true;

      settings = {
        auto_install = false;
        ensure_installed = [ ];
        ignore_install = [ ];
        # NOTE: This is our default, not the plugin's
        parser_install_dir.__raw = "vim.fs.joinpath(vim.fn.stdpath('data'), 'site')";

        sync_install = false;

        highlight = {
          additional_vim_regex_highlighting = false;
          enable = false;
          custom_captures = { };
          disable = null;
        };

        incremental_selection = {
          enable = false;
          keymaps = {
            init_selection = "gnn";
            node_incremental = "grn";
            scope_incremental = "grc";
            node_decremental = "grm";
          };
        };

        indent = {
          enable = false;
        };
      };
    };
  };

  empty = {
    plugins.treesitter.enable = true;
  };

  empty-grammar-packages = {
    plugins.treesitter = {
      enable = true;

      grammarPackages = [ ];
    };
  };

  highlight-disable-function = {
    plugins.treesitter = {
      enable = true;

      settings = {
        highlight = {
          enable = true;
          disable = ''
            function(lang, bufnr)
              return api.nvim_buf_line_count(bufnr) > 50000
            end
          '';
        };
      };
    };
  };

  nixvim-injections = {
    plugins.treesitter = {
      enable = true;
      nixvimInjections = true;

      languageRegister = {
        cpp = "onelab";
        python = [
          "foo"
          "bar"
        ];
      };
    };
  };

  no-nix = {
    # TODO: See if we can build parsers (legacy way)
    tests.dontRun = true;
    plugins.treesitter = {
      enable = true;
      nixGrammars = false;
    };
  };

  specific-grammars = {
    plugins.treesitter = {
      enable = true;

      grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        bash
        git_config
        git_rebase
        gitattributes
        gitcommit
        gitignore
        json
        jsonc
        lua
        make
        markdown
        meson
        ninja
        nix
        readline
        regex
        ssh-config
        toml
        vim
        vimdoc
        xml
        yaml
      ];
    };
  };

  combine-plugins = {
    performance.combinePlugins.enable = true;

    plugins.treesitter = {
      enable = true;

      # Exclude nixvim injections for test to pass
      nixvimInjections = false;
    };

    extraConfigLuaPost = ''
      -- Ensure that queries from nvim-treesitter are first in rtp
      local queries_path = "${pkgs.vimPlugins.nvim-treesitter}/queries"
      for name, type in vim.fs.dir(queries_path, {depth = 10}) do
        if type == "file" then
          -- Resolve all symlinks and compare nvim-treesitter's path with
          -- whatever we've got from runtime
          local nvim_treesitter_path = assert(vim.uv.fs_realpath(vim.fs.joinpath(queries_path, name)))
          local rtp_path = assert(
            vim.uv.fs_realpath(vim.api.nvim_get_runtime_file("queries/" .. name, false)[1]),
            name .. " not found in runtime"
          )
          assert(
            nvim_treesitter_path == rtp_path,
            string.format(
              "%s from rtp (%s) is not the same as from nvim-treesitter (%s)",
              name,
              rtp_path, nvim_treesitter_path
            )
          )
        end
      end
    '';
  };
}
