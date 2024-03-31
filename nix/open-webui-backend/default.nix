{ inputs, dream2nix, ... }: {
  imports = [
    dream2nix.modules.dream2nix.pip
  ];

  deps = {nixpkgs, ...}: {
    python = nixpkgs.python39;
  };

  name = "open-webui-backend";

  mkDerivation = {
    src = inputs.open-webui + /backend;
  };
  pip = {
    flattenDependencies = true;
    requirementsFiles = [
      "${inputs.open-webui}/backend/requirements.txt"
    ];
  };
}

