# Based on: https://github.com/juspay/rust-flake/blob/3a9001de75cf43adcb1df0783ef3125d93d0b24b/nix/modules/nixpkgs.nix#L1C1-L9C2
ollama-flake-inputs:
{ inputs, flake-parts-lib, ... }: {
  options.perSystem = flake-parts-lib.mkPerSystemOption ({ pkgs, system, ... }: 
  let
    open-webui-backend = ollama-flake-inputs.dream2nix.lib.evalModules {
      packageSets.nixpkgs = ollama-flake-inputs.dream2nix.inputs.nixpkgs.legacyPackages.${system};
      specialArgs = { inherit ollama-flake-inputs; };
      modules = [
        ../nix/open-webui/backend-env
        {
          paths.projectRoot = ../.;
          paths.projectRootFile = "flake.nix";
          paths.package = ../nix/open-webui/backend-env;
        }
      ];
    };
  in
  {
    imports = [
      "${inputs.nixpkgs}/nixos/modules/misc/nixpkgs.nix"
    ];
    nixpkgs = {
      hostPlatform = system;
      # Required for CUDA
      config.allowUnfree = true;
      overlays = [
        (self: _: with self; {
          inherit open-webui-backend;
          open-webui = callPackage (import ../nix/open-webui { inherit (ollama-flake-inputs) open-webui; }) { };
        })
      ];
    };
  });
}