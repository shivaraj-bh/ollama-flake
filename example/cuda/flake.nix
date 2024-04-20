{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    ollama-flake.url = "github:shivaraj-bh/ollama-flake";
    ollama-flake.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        inputs.process-compose-flake.flakeModule
        inputs.ollama-flake.flakeModules.nixpkgs
      ];
      perSystem = { self', pkgs, config, system, ... }: {
        process-compose.default = {
          imports = [
            inputs.ollama-flake.processComposeModules.default
          ];

          services.ollama = {
            enable = true;
            package = pkgs.ollama.override { acceleration = "cuda"; };
            extraEnvs = {
              # # See https://github.com/ollama/ollama/blob/9768e2dc7574c36608bb04ac39a3b79e639a837f/docs/gpu.md?plain=1#L32-L38
              # CUDA_VISIBLE_DEVICES = "0,2";
            };
            # Find more models at https://ollama.com/library
            models = [ "llama2-uncensored" ];
          };

          # Frontend client for Ollama
          services.open-webui.enable = true;
        };
      };
    };
}
