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
  };
}
