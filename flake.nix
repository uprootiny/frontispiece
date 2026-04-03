{
  description = "Frontispiece — practice-storytelling engine";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Elixir + Erlang
            elixir_1_18
            erlang_27
            rebar3

            # Rust (for TUI)
            rustc
            cargo

            # Assets
            nodejs_22  # esbuild/tailwind runners only
            asciinema

            # Database
            sqlite

            # Dev tools
            inotify-tools  # live reload (linux)
          ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            pkgs.darwin.apple_sdk.frameworks.CoreServices  # fsevents (mac)
          ];

          shellHook = ''
            export MIX_HOME=$PWD/.mix
            export HEX_HOME=$PWD/.hex
            export ERL_AFLAGS="-kernel shell_history enabled"
            echo "frontispiece dev shell ready"
          '';
        };
      }
    );
}
