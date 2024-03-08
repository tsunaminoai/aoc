{
  description = "virtual environments";

  inputs.devshell.url = "github:numtide/devshell";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.zig = {
    url = "github:mitchellh/zig-overlay";
    flake = true;
  };
  inputs.zls = {
    url = "github:zigtools/zls";
    flake = true;
  };

  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  outputs = {
    self,
    zig,
    zls,
    flake-utils,
    devshell,
    nixpkgs,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [devshell.overlays.default zig.overlays.default];
      };
      zig-master = zig.packages.${system}.master-2024-01-07; #mach-core 2024.1
    in {
      devShells.default = pkgs.devshell.mkShell {
        imports = [(pkgs.devshell.importTOML ./devshell.toml)];
        packages = [zig-master zls];
      };
    });
}