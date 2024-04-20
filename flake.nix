{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    dream2nix.url = "github:nix-community/dream2nix";
    dream2nix.inputs.nixpkgs.follows = "nixpkgs";
    # FIXME: use upstream after https://github.com/open-webui/open-webui/pull/1472 is released
    open-webui = {
      url = "github:shivaraj-bh/open-webui/304bf9d9b13fa1937a5d5bbff710e4237ca2d62b";
      flake = false;
    };
  };
  outputs = { dream2nix, open-webui, ... }: {
    processComposeModules.default = ./modules/process-compose-module.nix;
    flakeModules.nixpkgs = import ./modules/nixpkgs.nix { inherit dream2nix open-webui; };

    templates = {
      default = {
        description = "Example flake to run ollama (on CPU) with open-webui frontend";
        path = builtins.path { path = ./example/cpu; filter = path: _: baseNameOf path == "flake.nix"; };
      };

      cuda = {
        description = "Example flake to run ollama (with CUDA) with open-webui frontend";
        path = builtins.path { path = ./example/cuda; filter = path: _: baseNameOf path == "flake.nix"; };
      };

      rocm = {
        description = "Example flake to run ollama (with ROCm) with open-webui frontend";
        path = builtins.path { path = ./example/rocm; filter = path: _: baseNameOf path == "flake.nix"; };
      };
    };
  };
}
