---
name: devenv
description: Initialize and manage Nix flake development environments with auto-detection and security tooling
argument-hint: "[add|upgrade|remove|security]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
---

# Devenv Command

Initialize and manage Nix flake development environments. Provides a devbox-like experience with auto-detection of project dependencies and security tooling using native Nix solutions.

## Execution Flow

### Step 1: Check Current State

First, determine if this is a new setup or managing an existing environment:

1. Check if `flake.nix` exists in the current directory
2. If flake.nix exists, check if `git-hooks` input is present (indicates pre-commit is configured)
3. Read `.claude/devenv.local.md` if it exists for channel preference (default: `nixos-unstable`)

### Step 2: Branch Based on State

#### If flake.nix does NOT exist (Initialize Flow)

**2a. Auto-detect project stack:**

Scan for language indicator files and suggest packages:

| File | Stack | Suggested Packages |
|------|-------|-------------------|
| `package.json` | Node.js | `nodejs`, check lockfile for `pnpm`/`yarn`/`npm` |
| `pnpm-lock.yaml` | Node.js + pnpm | `nodejs`, `pnpm` |
| `yarn.lock` | Node.js + yarn | `nodejs`, `yarn` |
| `package-lock.json` | Node.js + npm | `nodejs` |
| `Cargo.toml` | Rust | `rustc`, `cargo`, `rust-analyzer` |
| `go.mod` | Go | `go`, `gopls` |
| `pyproject.toml` | Python | `python3`, `uv` |
| `requirements.txt` | Python | `python3`, `pip` |
| `Gemfile` | Ruby | `ruby`, `bundler` |
| `pom.xml` | Java | `jdk`, `maven` |
| `build.gradle` | Java/Kotlin | `jdk`, `gradle` |
| `*.csproj` | .NET | `dotnet-sdk` |
| `Makefile` | C/C++ | `gnumake`, `gcc` |
| `CMakeLists.txt` | C/C++ | `cmake`, `gcc` |
| `Dockerfile` | Docker | `docker` |

Also read `CLAUDE.md` if it exists to understand the project context and tech stack.

**2b. Present detected packages:**

Use AskUserQuestion with multiSelect to show detected packages:
```
Based on your repository, I detected these packages:
[x] nodejs_22
[x] pnpm
[x] typescript
```

Let user confirm, deselect, or add more via "Other" option.

**2c. Ask for additional packages:**

Ask: "Any additional packages you need? (e.g., redis, postgresql, jq)"

For each package mentioned:
1. Run `nix-shell -p nix --run "nix search nixpkgs <package> --json"` to find exact package names
2. If version specified (e.g., `nodejs@20`), search for versioned variants like `nodejs_20`
3. Present search results and confirm selection

**2d. Offer security tools:**

Use AskUserQuestion with multiSelect:
```
Security tools (recommended):
[ ] pre-commit - Git hooks with SAST tools for your stack (using git-hooks.nix)
```

If pre-commit selected, determine which git-hooks.nix hooks to enable based on detected stack:

| Stack | Hooks to Enable |
|-------|-----------------|
| JavaScript/TypeScript | `eslint.enable = true; prettier.enable = true;` |
| Python | `ruff.enable = true; ruff-format.enable = true;` |
| Go | `golangci-lint.enable = true;` |
| Rust | `clippy.enable = true; rustfmt.enable = true;` |
| Nix (always) | `nixfmt-rfc-style.enable = true; statix.enable = true; deadnix.enable = true;` |
| Shell scripts | `shellcheck.enable = true;` |
| Docker | `hadolint.enable = true;` |
| General (always) | `check-yaml.enable = true; trim-trailing-whitespace.enable = true;` |

**Then ask about secret scanning:**

Use AskUserQuestion:
```
Secret scanner preference:
○ trufflehog (Recommended) - Built-in hook, works out of the box
○ gitleaks - Popular choice, requires custom hook configuration
○ None - Skip secret scanning
```

If trufflehog selected:
- Add `trufflehog.enable = true;` to the hooks configuration (built-in, no extra config needed)

If gitleaks selected:
- Add gitleaks as a **custom hook** (it's NOT built-in to git-hooks.nix):
```nix
gitleaks = {
  enable = true;
  name = "gitleaks";
  entry = "${pkgs.gitleaks}/bin/gitleaks git --pre-commit --redact --staged --verbose";
  language = "system";
  pass_filenames = false;
};
```
- Also add `gitleaks` to the packages list
- If pre-commit not selected, still add `gitleaks` to packages for manual use

**2e. Generate files:**

1. Generate `flake.nix` using the appropriate template:

**Basic Template (without pre-commit):**

```nix
{
  description = "Development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            # PACKAGES_HERE
          ];

          shellHook = ''
            echo "╔══════════════════════════════════════╗"
            echo "║            🔧 devenv                 ║"
            echo "║     Development environment loaded   ║"
            echo "╚══════════════════════════════════════╝"
          '';
        };
      }
    );
}
```

**Template with git-hooks.nix (pre-commit enabled):**

```nix
{
  description = "Development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    git-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    git-hooks,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

        # Pre-commit hooks configuration
        pre-commit-check = git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            # Nix
            nixfmt-rfc-style.enable = true;
            statix.enable = true;
            deadnix.enable = true;

            # General
            check-yaml.enable = true;
            trim-trailing-whitespace.enable = true;

            # LANGUAGE_HOOKS_HERE

            # SECRET_SCANNER_HERE
            # For trufflehog (built-in): trufflehog.enable = true;
            # For gitleaks (custom hook):
            # gitleaks = {
            #   enable = true;
            #   name = "gitleaks";
            #   entry = "${pkgs.gitleaks}/bin/gitleaks git --pre-commit --redact --staged --verbose";
            #   language = "system";
            #   pass_filenames = false;
            # };
          };
        };
      in {
        # Run hooks in CI with: nix flake check
        checks.pre-commit-check = pre-commit-check;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            # PACKAGES_HERE
          ] ++ pre-commit-check.enabledPackages;

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
```

2. Generate `.envrc`:
```bash
use flake
```

3. Update `.gitignore` to exclude generated files:
   - Check if `.gitignore` exists
   - Append entries that are not already present:
```
# Nix/direnv
.direnv/
.pre-commit-config.yaml
```

4. Run `nix flake lock` to generate `flake.lock`

**2f. Output instructions:**

```
Development environment created!

To enter the environment:
  nix develop

Or with direnv (recommended):
  direnv allow

Your environment includes:
- [list packages]

[If pre-commit was selected:]
Pre-commit hooks are configured via git-hooks.nix.
They will auto-install when you run `nix develop`.

Available hooks:
- [list enabled hooks]

To run hooks manually: pre-commit run --all-files
To validate in CI: nix flake check
```

---

#### If flake.nix EXISTS (Manage Flow)

**2a. Parse current state:**

1. Read `flake.nix` and extract current packages from `packages = with pkgs; [ ... ]`
2. Check if `git-hooks` input exists in flake.nix (indicates pre-commit is configured)

**2b. Ask what to do:**

Use AskUserQuestion:
```
What would you like to do?
○ Add packages - Add new packages to your environment
○ Upgrade packages - Update flake.lock to get latest versions
○ Remove packages - Remove packages from your environment
○ Setup security tools - Add pre-commit and gitleaks (only if not configured)
```

Only show "Setup security tools" option if `git-hooks` input is NOT present in flake.nix.

**2c. Handle selected action:**

**Add packages:**
1. Ask: "What packages would you like to add?"
2. Search nixpkgs for each: `nix-shell -p nix --run "nix search nixpkgs <package> --json"`
3. Confirm package names
4. Edit `flake.nix` to add packages to the list
5. Run `nix flake lock --update-input nixpkgs` to update lock

**Upgrade packages:**
1. Run `nix flake update` to update all inputs
2. Show what was updated from the output

**Remove packages:**
1. Show current packages list with checkboxes (multiSelect)
2. Let user select which to remove
3. Edit `flake.nix` to remove selected packages

**Setup security tools:**
1. Follow the same flow as step 2d from Initialize Flow
2. Add `git-hooks` input to flake.nix
3. Add the `pre-commit-check` configuration
4. Update the devShell to include `pre-commit-check.enabledPackages` and shellHook
5. Add the `checks.pre-commit-check` output

---

## Important Notes

- Always use `nix-shell -p <tool> --run "<command>"` for nix tools - do NOT assume they are installed system-wide
- The PostToolUse hooks will automatically format and lint `flake.nix` after any Write/Edit operations
- Use the nixpkgs channel from `.claude/devenv.local.md` if it exists, otherwise default to `nixos-unstable`
- When searching for packages, prefer the `--json` flag for easier parsing
- `git-hooks.nix` auto-generates `.pre-commit-config.yaml` via shellHook - no manual YAML needed!
- All hook tools are provided by Nix, ensuring reproducibility

## Settings File

Users can customize behavior via `.claude/devenv.local.md`:

```yaml
---
nixpkgs_channel: nixos-unstable
---
```

## git-hooks.nix Hook Reference

### Available Hooks by Language

| Language | Hook Names |
|----------|------------|
| JavaScript/TypeScript | `eslint`, `prettier` |
| Python | `ruff`, `ruff-format`, `black`, `mypy` |
| Go | `golangci-lint`, `gofmt` |
| Rust | `clippy`, `rustfmt`, `cargo-check` |
| Nix | `nixfmt-rfc-style`, `statix`, `deadnix` |
| Shell | `shellcheck`, `shfmt` |
| Docker | `hadolint` |
| YAML | `check-yaml`, `yamllint` |
| Secrets | `trufflehog`, `ripsecrets` (built-in); `gitleaks` requires custom config |
| General | `trim-trailing-whitespace`, `check-added-large-files`, `check-merge-conflicts` |

### Example Hook Configuration

```nix
hooks = {
  # Enable a built-in hook
  eslint.enable = true;

  # Built-in secret scanner
  trufflehog.enable = true;

  # Enable with custom settings
  ruff = {
    enable = true;
    settings.args = ["--fix"];
  };

  # Custom hook example: gitleaks (not built-in)
  gitleaks = {
    enable = true;
    name = "gitleaks";
    entry = "${pkgs.gitleaks}/bin/gitleaks git --pre-commit --redact --staged --verbose";
    language = "system";
    pass_filenames = false;
  };
};
```

For full list of available hooks, see: https://github.com/cachix/git-hooks.nix
