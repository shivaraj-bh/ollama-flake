{ ollama-flake-inputs, config, dream2nix, ... }: {
  imports = [
    dream2nix.modules.dream2nix.WIP-python-pdm
  ];

  deps = { nixpkgs, ... }: {
    python = nixpkgs.python310;
    inherit (nixpkgs) writeShellApplication;
  };

  name = "open-webui-backend";

  mkDerivation = {
    src = ollama-flake-inputs.open-webui + /backend;
    buildInputs = [
      config.deps.python.pkgs.pdm-backend
    ];
  };

  public.req2py =
    let
      pdmConfig = config.deps.writeText "pdm-config.toml" ''
        check_update = false
        [python]
        use_venv = false
      '';
    in
    config.deps.writeShellApplication {
      name = "pdm-req2py";
      runtimeInputs = with config.deps; [ pdm coreutils python ];
      # Based on: https://github.com/nix-community/dream2nix/blob/442b2ce83d76158793f347db998545d6bdf05611/modules/dream2nix/WIP-python-pdm/lock.nix#L13-L34
      # TODO: reuse it after upstreaming `pdm import` support
      text = ''
        set -Eeuo pipefail

        TMPDIR=$(mktemp -d)
        export TMPDIR
        trap 'chmod -R +w "$TMPDIR"; rm -rf "$TMPDIR"' EXIT

        # vscode likes to set these for whatever reason and it crashes PDM
        unset _PYTHON_SYSCONFIGDATA_NAME _PYTHON_HOST_PLATFORM

        pushd "$(${config.paths.findRoot})/${config.paths.package}"

        which python3 > .pdm-python

        pdm -c ${pdmConfig} import ${ollama-flake-inputs.open-webui}/backend/requirements.txt

        popd
      '';
    };

  pdm.lockfile = ./pdm.lock;
  pdm.pyproject = ./pyproject.toml;

}
