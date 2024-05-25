{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    ollama-flake.url = "github:shivaraj-bh/ollama-flake/private-gpt";
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
            # TODO: pick the models from private-gpt's `defaultSettings` only if they are not overriden by `extraSettings`
            models = with config.process-compose.default.services.private-gpt.defaultSettings.ollama; [
              llm_model
              embedding_model
            ];
          };

          # Frontend client for Ollama
          services.private-gpt.enable = true;

          settings.processes.private-gpt.depends_on."ollama-models".condition = "process_completed_successfully";
        };
      };
    };
}
