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
      url = "github:shivaraj-bh/open-webui/304bf9d9b13fa1937a5d5bbff710e4237ca2d62b";
      flake = false;
    };
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        inputs.process-compose-flake.flakeModule
      ];
      perSystem = { self', pkgs, config, system, ... }:
        let
          open-webui-backend-module = inputs.dream2nix.lib.evalModules {
            packageSets.nixpkgs = inputs.dream2nix.inputs.nixpkgs.legacyPackages.${system};
            specialArgs = { inherit inputs; };
            modules = [
              ./nix/open-webui/backend-env
              {
                paths.projectRoot = ./.;
                paths.projectRootFile = "flake.nix";
                paths.package = ./nix/open-webui/backend-env;
              }
            ];
          };
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            # Required for CUDA
            config.allowUnfree = true;
            overlays = [
              (self: _: with self; {
                open-webui-backend-env = open-webui-backend-module.pyEnv;
                open-webui = callPackage (import ./nix/open-webui { inherit (inputs) open-webui; }) { };
              })
            ];
          };

          packages.open-webui-backend-lock = open-webui-backend-module.lock;
          packages.open-webui-backend-req2py = open-webui-backend-module.req2py;

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
                  extraEnvs = {
                    # # See https://github.com/ollama/ollama/blob/9768e2dc7574c36608bb04ac39a3b79e639a837f/docs/gpu.md?plain=1#L32-L38
                    # CUDA_VISIBLE_DEVICES = "0,2";
                  };
                };
              };
              rocm = {
                imports = [ common ];
                services.ollama-stack.extraOllamaConfig = {
                  package = pkgs.ollama.override { acceleration = "rocm"; };
                  extraEnvs = {
                    # # See https://github.com/ollama/ollama/blob/9768e2dc7574c36608bb04ac39a3b79e639a837f/docs/gpu.md?plain=1#L55-L86
                    # HSA_OVERRIDE_GFX_VERSION = “10.3.0”;
                    # # See docs: https://rocm.docs.amd.com/en/latest/conceptual/gpu-isolation.html#rocr-visible-devices
                    # ROCR_VISIBLE_DEVICES = "0,GPU-DEADBEEFDEADBEEF";
                    # # See https://rocm.docs.amd.com/en/latest/conceptual/gpu-isolation.html#hip-visible-devices
                    # HIP_VISIBLE_DEVICES = "0,2";
                  };
                };
              };
            };
        };
    };
}

