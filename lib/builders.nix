{ lib, pkgs }:
{
  /*
    Write a lua file to the nix store, formatted using stylua.

    # Type

    ```
    writeLua :: String -> String -> Derivation
    ```

    # Arguments

    - [name] The name of the derivation
    - [text] The content of the lua file
  */
  writeLua =
    name: text:
    pkgs.runCommand name { inherit text; } ''
      echo -n "$text" > "$out"

      ${lib.getExe pkgs.stylua} \
        --no-editorconfig \
        --line-endings Unix \
        --indent-type Spaces \
        --indent-width 4 \
        "$out"
    '';

  /*
    Write a byte compiled lua file to the nix store.

    # Type

    ```
    writeByteCompiledLua :: String -> String -> Derivation
    ```

    # Arguments

    - [name] The name of the derivation
    - [text] The content of the lua file
  */
  writeByteCompiledLua =
    name: text:
    pkgs.runCommandLocal name { inherit text; } ''
      echo -n "$text" > "$out"

      ${lib.getExe' pkgs.luajit "luajit"} -bd -- "$out" "$out"
    '';

  # Setup hook to byte compile all lua files in output directory
  byteCompileLuaHook = pkgs.makeSetupHook { name = "byte-compile-lua-hook"; } (
    let
      luajit = lib.getExe' pkgs.luajit "luajit";
    in
    pkgs.writeText "byte-compile-lua-hook.sh" # bash
      ''
        byteCompileLuaPostFixup() {
            while IFS= read -r -d "" file; do
                tmp=$(mktemp -u "$file.XXXX")
                if ${luajit} -bd -- "$file" "$tmp"; then
                    mv "$tmp" "$file"
                fi
            done < <(find "$out" -type f,l -name "*.lua" -print0)
        }

        postFixupHooks+=(byteCompileLuaPostFixup)
      ''
  );
}
