# nixify-ollama

Run Ollama stack (the server and interactive webui) natively with a single command, using [services-flake](https://github.com/juspay/services-flake).

## Getting started

### CPU; with open-webui
```sh
nix run
```

### GPU; CUDA
```sh
nix run .#cuda
```

### GPU; ROCm
```sh
nix run .#rocm
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

