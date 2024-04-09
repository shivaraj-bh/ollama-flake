{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    services-flake.url = "github:juspay/services-flake/ollama";
    ollama-flake.url = "path:../..";
    ollama-flake.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        inputs.process-compose-flake.flakeModule
        inputs.ollama-flake.flakeModules.nixpkgs
      ];
      perSystem = { self', pkgs, config, system, ... }:{
          process-compose.default = {
            imports = [
              inputs.services-flake.processComposeModules.default
              inputs.ollama-flake.processComposeModules.default
            ];

            services.ollama-stack = {
              enable = true;
              open-webui.enable = true;
            };
          };
        };
    };
}
