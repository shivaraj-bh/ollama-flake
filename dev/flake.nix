{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    ollama-flake.url = "github:shivaraj-bh/ollama-flake";
    nixpkgs.follows = "ollama-flake/nixpkgs";
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        inputs.ollama-flake.flakeModules.nixpkgs
      ];
      perSystem = { self', pkgs, config, system, ... }: {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            just
            nixd
          ];
          shellHook = ''
            echo
            echo "🍎🍎 Run 'just <recipe>' to get started"
            just
          '';
        };
        packages.lock = pkgs.open-webui-backend.lock;
        packages.req2py = pkgs.open-webui-backend.req2py;
      };
    };
}
