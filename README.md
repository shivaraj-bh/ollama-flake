# ollama-flake

> [!NOTE] 
> 🚜 This repository is archived as the services here have been upstreamed to [services-flake](https://github.com/juspay/services-flake). See an example of its usage: <https://github.com/juspay/services-flake/tree/main/example/llm> 

Run Ollama stack (the [server](https://github.com/ollama/ollama) and [interactive webui](https://github.com/open-webui/open-webui)) natively.

## Getting started

```sh
mkdir my-ollama-flake && cd ./my-ollama-flake
nix flake init -t github:shivaraj-bh/ollama-flake
nix run
```

See [examples](./example) for more details.

## Discussions

[Join our zulip](https://nixos.zulipchat.com/#narrow/stream/426237-nixify-llm)
