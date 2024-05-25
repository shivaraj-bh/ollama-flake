# List all the just commands
default:
  @just --list

# Run example/cpu
ex-cpu:
  cd ./example/cpu && nix run . --override-input ollama-flake ../..

# Run example/private-gpt on cpu
ex-pg:
  cd ./example/private-gpt && nix run . --override-input ollama-flake ../..

# Run example/cuda
ex-cuda:
  cd ./example/cuda && nix run . --override-input ollama-flake ../..

# Run example/rocm
ex-rocm:
  cd ./example/rocm && nix run . --override-input ollama-flake ../..

# Update pdm.lock (locks open-webui's python deps) 
pdm-update:
  # Convert `requirements.txt` to `pyproject.toml`
  nix run ./dev#req2py --override-input ollama-flake .
  nix run ./dev#lock --override-input ollama-flake .


