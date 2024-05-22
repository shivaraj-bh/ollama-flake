{ config, dream2nix, ... }: {
  imports = [
    dream2nix.modules.dream2nix.WIP-python-pdm
  ];

  deps = { nixpkgs, ... }: {
    python = nixpkgs.python310;
    inherit (nixpkgs)
      writeShellApplication
      fetchFromGitHub;
  };

  name = "open-webui-backend";

  mkDerivation = {
    src = config.public.src + /backend;
    buildInputs = [
      config.deps.python.pkgs.pdm-backend
    ];
  };

  public.version = "0.1.124";

  public.src = config.deps.fetchFromGitHub {
    owner = "open-webui";
    repo = "open-webui";
    rev = "v${config.public.version}";
    hash = "sha256-r3oZiN2UIhPAG+ZcsZrXD1OemJrWXXlZdKVhK3+VhhU=";
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

        [ -f pyproject.toml ] && rm pyproject.toml

        which python3 > .pdm-python

        pdm -c ${pdmConfig} import ${config.public.src}/backend/requirements.txt

        popd
      '';
    };

  # pip.requirementsFiles = [ "${config.mkDerivation.src}/requirements.txt" ];

  pdm.lockfile = ./pdm.lock;
  pdm.pyproject = ./pyproject.toml;

}
