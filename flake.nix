{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    services-flake.url = "github:juspay/services-flake/ollama";
    dream2nix.url = "github:nix-community/dream2nix";
    dream2nix.inputs.nixpkgs.follows = "nixpkgs";

    open-webui = {
      url = "github:open-webui/open-webui/v0.1.114";
      flake = false;
    };
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        inputs.process-compose-flake.flakeModule
      ];
      debug = true;
      perSystem = { self', pkgs, config, system, ... }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          # Required for CUDA
          config.allowUnfree = true;
          overlays = [
            (self: _: with self; {
              open-webui-frontend = callPackage (import ./nix/open-webui-frontend.nix { inherit inputs; }) { };
            })
          ];
        };
        packages.open-webui-backend = inputs.dream2nix.lib.evalModules {
          packageSets.nixpkgs = inputs.dream2nix.inputs.nixpkgs.legacyPackages.${system};
          specialArgs = { inherit inputs; };
          modules = [
            ./nix/open-webui-backend
            {
              paths.projectRoot = ./.;
              # can be changed to ".git" or "flake.nix" to get rid of .project-root
              paths.projectRootFile = "flake.nix";
              paths.package = ./nix/open-webui-backend;
            }
          ];
        };
        process-compose =
          let
            common = { ... }: {
              imports = [
                inputs.services-flake.processComposeModules.default
                (import ./nix/ollama.nix { inherit self' inputs; })
              ];
              services.ollama-stack.enable = true;
            };
          in
          {
            default = {
              imports = [ common ];
              services.ollama-stack.open-webui.enable = true;
            };
            cuda = {
              imports = [ common ];
              services.ollama-stack.extraOllamaConfig = {
                package = pkgs.ollama.override { acceleration = "cuda"; };
              };
            };
            rocm = {
              imports = [ common ];
              services.ollama-stack.extraOllamaConfig = {
                package = pkgs.ollama.override { acceleration = "rocm"; };
              };
            };
          };
      };
    };
}

