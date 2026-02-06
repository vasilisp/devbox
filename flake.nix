{
  description = "Bootstrap dev tools (editors, VCS, env managers, CLIs)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, rust-overlay }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];

      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system:
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ rust-overlay.overlays.default ];
              config.allowUnfree = true;
            };
          in
            f pkgs
        );
    in
      {
        packages = forAllSystems (pkgs: {
          default = pkgs.buildEnv {
            name = "dev-bootstrap";

            paths = with pkgs; [
              # editors / UI entry points
              emacs-nox
              tmux

              # VCS & core CLI
              git
              htop
              jq
              ripgrep

              # environment / toolchain bootstrap
              direnv
              nix-direnv
              uv

              # AI / external CLIs
              claude-code
              gemini-cli
            ];
          };
        });

        devShells = forAllSystems (pkgs:
          let
            rustToolchain =
              pkgs.rust-bin.stable.latest.default.override {
                extensions = [
                  "rustfmt"
                  "clippy"
                  "rust-src"
                ];
              };
          in
            {
              default = pkgs.mkShell {
                packages = with pkgs; [
                  cmake
                  pkg-config
                  rustToolchain
                ];
              };
            }
        );
      };
}
