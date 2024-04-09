# open-webui-backend

This package depends on `pyproject.toml` and `pdm.lock` file. The `pyproject.toml` is generated with `pdm import` on the `requirements.txt` file of `open-webui/backend`.

To generate the `pyproject.toml` run:

```sh
nix run .#open-webui-backend-req2py
```

And to generate the `pdm.lock` file using the `pyproject.toml`:

```sh
nix run .#open-webui-backend-lock
```
