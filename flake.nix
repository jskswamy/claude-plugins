{
  description = "Development environment for Claude Code plugin marketplace";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    git-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      git-hooks,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Pre-commit hooks configuration
        pre-commit-check = git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            # Nix
            nixfmt-rfc-style.enable = true;
            statix.enable = true;
            deadnix = {
              enable = true;
              settings.edit = true;
              settings.noLambdaPatternNames = true;
            };

            # Shell
            shellcheck.enable = true;

            # Spell checking
            typos.enable = true;

            # Secrets
            trufflehog.enable = true;

            # General
            check-yaml.enable = true;
            trim-trailing-whitespace.enable = true;
          };
        };
      in
      {
        # Run hooks in CI with: nix flake check
        checks.pre-commit-check = pre-commit-check;

        devShells.default = pkgs.mkShell {
          packages =
            with pkgs;
            [
              # Shell script linting
              shellcheck

              # Spell checking
              typos

              # Changelog generation
              git-cliff
            ]
            ++ pre-commit-check.enabledPackages;

          shellHook = ''
            ${pre-commit-check.shellHook}
            echo "╔══════════════════════════════════════╗"
            echo "║            🔧 devenv                 ║"
            echo "║     Development environment loaded   ║"
            echo "╚══════════════════════════════════════╝"
          '';
        };
      }
    );
}
