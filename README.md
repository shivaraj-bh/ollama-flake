# ollama-flake

Run Ollama stack (the [server](https://github.com/ollama/ollama) and [interactive webui](https://github.com/open-webui/open-webui)) natively, using [services-flake](https://github.com/juspay/services-flake).

## Getting started

```sh
mkdir my-ollama-flake && cd ./my-ollama-flake
nix flake init -t github:shivaraj-bh/ollama-flake
nix run
```

See [examples](./example) for more details.

## Discussions

[Join our zulip](https://nixos.zulipchat.com/#narrow/stream/426237-nixify-llm)
