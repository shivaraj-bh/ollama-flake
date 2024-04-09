# open-webui-backend

This package depends on `pyproject.toml` and `pdm.lock` file. The `pyproject.toml` is generated with `pdm import` on the `requirements.txt` file of `open-webui/backend`.

To generate the `pyproject.toml` run:

```sh
nix run ./dev#req2py --override-input ollama-flake .
```

And to generate the `pdm.lock` file using the `pyproject.toml`:

```sh
nix run ./dev#lock --override-input ollama-flake .
```

Or do both in one command (after entering the `devShell` of `./dev/flake.nix`):

```sh
just pdm-update
```
