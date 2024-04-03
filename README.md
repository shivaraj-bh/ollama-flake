# ollama-flake

Run Ollama stack (the [server](https://github.com/ollama/ollama) and [interactive webui](https://github.com/open-webui/open-webui)) natively, using [services-flake](https://github.com/juspay/services-flake).

## Getting started

### CPU; with open-webui
```sh
nix run github:shivaraj-bh/ollama-flake
```

### GPU; CUDA
```sh
nix run github:shivaraj-bh/ollama-flake#cuda
```

### GPU; ROCm
```sh
nix run github:shivaraj-bh/ollama-flake#rocm
```

## Up Next

- [x] Open browser (`xdg-open` on Linux and `open` on MacOS) after the frontend process starts
- [ ] Test GPU acceleration and document the process
  - [x] Tested on CUDA. Need to document the driver compatiblity issues, with solutions.
- [ ] MacOS support
- [ ] Add tests/CI
- [ ] Export home-manager configuration for ollama server (inspired by NixOS' ollama service module)

## Discussions

[Join our zulip](https://nixos.zulipchat.com/#narrow/stream/426237-nixify-llm)

