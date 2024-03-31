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
        process-compose.default = {
          imports = [
            inputs.services-flake.processComposeModules.default
          ];
          services.ollama."ollama" = {
            enable = true;
            host = "0.0.0.0";
            models = [ "llama2-uncensored" ];
          };
          settings.processes.open-webui = 
          let
            ollama-cfg = config.process-compose.default.services.ollama.ollama;
          in
          {
            command = pkgs.writeShellApplication {
              name = "open-webui";
              runtimeInputs = [ self'.packages.open-webui-backend.pyEnv ];
              text = ''
                set -x
                # TODO: make a service and give it a dataDir option
                if [ -d ./data/open-webui ]; then
                  rm -rf ./data/open-webui
                fi
                mkdir -p ./data/open-webui/build
                cp -r ${inputs.open-webui}/. ./data/open-webui
                # There is FRONTEND_BUILD_DIR, but backend is hardcoded to find some components of the frontend in the parent directory, like the favicon in `backend/config.py`
                
                cp -r ${pkgs.open-webui-frontend}/share/open-webui/. ./data/open-webui/build
                chmod -R u+rw ./data/open-webui
                cd ./data/open-webui/backend

                OLLAMA_API_BASE_URL=${ollama-cfg.host}:${builtins.toString ollama-cfg.port}/api
                export OLLAMA_API_BASE_URL
                uvicorn main:app --host 0.0.0.0 --port 1111 --forwarded-allow-ips '*'
              '';
            };
            depends_on."ollama-models".condition = "process_completed_successfully";
          };
        };
      };
    };
}

