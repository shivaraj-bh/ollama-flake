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
            # Find more models at https://ollama.com/library
            models = [ "llama2-uncensored" ];
          };

          # Frontend client for Ollama
          services.open-webui.enable = true;
        };
      };
    };
}
