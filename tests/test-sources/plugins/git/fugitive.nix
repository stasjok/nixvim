{
  empty = {
    plugins.fugitive.enable = true;
  };

  # combinePlugins when both mini.nvim and fugitive.vim are installed
  combine-plugins = {
    plugins = {
      fugitive.enable = true;
      mini.enable = true;
    };

    performance.combinePlugins.enable = true;
  };
}
