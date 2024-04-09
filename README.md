# ollama-flake

Run Ollama stack (the [server](https://github.com/ollama/ollama) and [interactive webui](https://github.com/open-webui/open-webui)) natively, using [services-flake](https://github.com/juspay/services-flake).

## Getting started

```sh
nix run "github:shivaraj-bh/ollama-flake?dir=example/cpu"
```

See [examples](./example) to use them in your flake.

## Up Next

- [x] Open browser (`xdg-open` on Linux and `open` on MacOS) after the frontend process starts
- [ ] Test GPU acceleration and document the process
  - [x] Tested on CUDA. Need to document the driver compatiblity issues, with solutions.
- [x] MacOS support <https://github.com/shivaraj-bh/ollama-flake/pull/3>
- [x] Export `processComposeModule` and add examples
- [ ] Add tests/CI
- [ ] Export home-manager configuration for ollama server (inspired by NixOS' ollama service module)

## Discussions

[Join our zulip](https://nixos.zulipchat.com/#narrow/stream/426237-nixify-llm)

