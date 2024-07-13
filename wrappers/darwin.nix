self:
{
  pkgs,
  config,
  lib,
  ...
}@args:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkOptionType
    mkForce
    mkMerge
    mkIf
    types
    ;
  cfg = config.programs.nixvim;
in
{
  options = {
    programs.nixvim = mkOption {
      default = { };
      type = types.submoduleWith {
        shorthandOnlyDefinesConfig = true;
        specialArgs = {
          darwinConfig = config;
          defaultPkgs = pkgs;
          inherit (config.nixvim) helpers;
        };
        modules = [
          ./modules/darwin.nix
          ../modules/top-level
        ];
      };
    };
  };

  imports = [ (import ./_shared.nix { }) ];

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = [
        cfg.finalPackage
        cfg.printInitPackage
      ] ++ (lib.optional cfg.enableMan self.packages.${pkgs.stdenv.hostPlatform.system}.man-docs);
    }
    { inherit (cfg) warnings assertions; }
  ]);
}
