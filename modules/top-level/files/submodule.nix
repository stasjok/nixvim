{
  name,
  config,
  lib,
  pkgs,
  helpers,
  ...
}:
{
  options = {
    plugin = lib.mkOption {
      type = lib.types.package;
      description = "A derivation with the content of the file in it";
      readOnly = true;
      internal = true;
    };
  };
  config =
    let
      derivationName = "nvim-" + lib.replaceStrings [ "/" ] [ "-" ] name;
    in
    {
      path = lib.mkDefault name;
      type = lib.mkDefault (if lib.hasSuffix ".vim" name then "vim" else "lua");
      # No need to use mkDerivedConfig; this option is readOnly.
      plugin =
        let
          writeContent = if config.type == "lua" then helpers.writeLua else pkgs.writeText;
        in
        writeContent derivationName config.content;
    };
}
