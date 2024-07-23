{
  # Option path where extraFiles should go
  filesOpt ? null,
  # Filepath prefix to apply to extraFiles
  filesPrefix ? "nvim/",
  # Filepath to use when adding `cfg.initPath` to `filesOpt`
  # Is prefixed with `filesPrefix`
  initName ? "init.lua",
}:
{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    isAttrs
    listToAttrs
    map
    mkIf
    mkMerge
    mkOption
    mkOptionType
    optionalAttrs
    setAttrByPath
    ;
  cfg = config.programs.nixvim;
  inherit (config.nixvim) helpers;
  extraFiles = lib.filter (file: file.enable) (lib.attrValues cfg.extraFiles);
in
{
  options = {
    nixvim.helpers = mkOption {
      type = mkOptionType {
        name = "helpers";
        description = "Helpers that can be used when writing nixvim configs";
        check = isAttrs;
      };
      description = "Use this option to access the helpers";
    };
  };

  config = mkMerge [
    # Make our lib available to the host modules
    { nixvim.helpers = lib.mkDefault (import ../lib/helpers.nix { inherit pkgs lib; }); }
    # Propagate extraFiles to the host modules
    (optionalAttrs (filesOpt != null) (
      mkIf (!cfg.wrapRc) (
        setAttrByPath filesOpt (
          listToAttrs (
            map (
              { target, source, ... }:
              let
                maybeByteCompile =
                  source:
                  let
                    name =
                      if lib.isStorePath source then
                        builtins.substring 33 (-1) (baseNameOf source)
                      else
                        baseNameOf source;
                  in
                  if
                    lib.hasSuffix ".lua" source
                    && cfg.performance.byteCompileLua.enable
                    && cfg.performance.byteCompileLua.configs
                  then
                    helpers.writeByteCompiledLua name (builtins.readFile source)
                  else
                    source;
              in
              {
                name = filesPrefix + target;
                value = {
                  source = maybeByteCompile source;
                };
              }
            ) extraFiles
          )
          // {
            ${filesPrefix + initName}.source = cfg.initPath;
          }
        )
      )
    ))
  ];
}
