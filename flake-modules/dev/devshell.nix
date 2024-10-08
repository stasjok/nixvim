{ lib, inputs, ... }:
{
  imports = lib.optional (inputs.devshell ? flakeModule) inputs.devshell.flakeModule;

  perSystem =
    {
      lib,
      pkgs,
      config,
      system,
      ...
    }:
    lib.optionalAttrs (inputs.devshell ? flakeModule) {
      devshells.default = {
        devshell.startup.pre-commit.text = config.pre-commit.installationScript;

        commands =
          let
            # Thanks to this, the user can choose to use `nix-output-monitor` (`nom`) instead of plain `nix`
            nix = ''$([ "$\{NIXVIM_NOM:-0}" = '1' ] && echo ${pkgs.lib.getExe pkgs.nix-output-monitor} || echo nix)'';
          in
          [
            {
              name = "checks";
              help = "Run all nixvim checks";
              command = ''
                echo "=> Running all nixvim checks..."

                ${nix} flake check "$@"
              '';
            }
            {
              name = "tests";
              help = "Run nixvim tests";
              command =
                let
                  launchTest = pkgs.writeShellApplication {
                    name = "launch-tests";
                    runtimeInputs = with pkgs; [
                      getopt
                      jq
                      fzf
                    ];

                    text = builtins.readFile ./launch-test.sh;
                  };
                in
                ''
                  NIXVIM_SYSTEM=${system} NIXVIM_NIX_COMMAND=${nix} ${lib.getExe launchTest} "$@"
                '';
            }
            {
              name = "test-lib";
              help = "Run nixvim library tests";
              command = ''
                echo "=> Running nixvim library tests for the '${system}' architecture..."

                ${nix} build .#checks.${system}.lib-tests "$@"
              '';
            }
            {
              name = "format";
              help = "Format the entire codebase";
              command = "nix fmt";
            }
            {
              name = "docs";
              help = "Build nixvim documentation";
              command = ''
                echo "=> Building nixvim documentation..."

                ${nix} build .#docs "$@"
              '';
            }
            {
              name = "serve-docs";
              help = "Build and serve documentation locally";
              command = ''
                echo -e "=> Building nixvim documentation...\n"

                doc_derivation=$(${nix} build .#docs --no-link --print-out-paths)

                echo -e "\n=> Documentation successfully built ('$doc_derivation')"

                echo -e "\n=> You can then open your browser to view the doc\n"

                (cd "$doc_derivation"/share/doc && ${pkgs.lib.getExe pkgs.python3} ${./server.py})
              '';
            }
            {
              name = "list-plugins";
              command = "${pkgs.python3.interpreter} ${./list-plugins.py}";
              help = "List plugins and get implementation infos";
            }
          ];
      };
    };
}
