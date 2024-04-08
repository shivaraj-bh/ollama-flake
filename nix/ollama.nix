{ self', inputs }:
{ pkgs, config, lib, ... }:
{
  options = {
    services.ollama-stack = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "Enable ollama-stack comprising ollama server and other client processes";

          extraOllamaConfig = lib.mkOption {
            type = lib.types.deferredModule;
            default = { };
            description = ''
              Extra Ollama service config.
            '';
          };

          open-webui = lib.mkOption {
            type = lib.types.submodule {
              options = {
                enable = lib.mkEnableOption "Enable open-webui, an interactive chat web app";
              };
            };
            default = { };
            defaultText = ''
              open-webui disabled by default
            '';
          };
        };
      };
    };
  };
  config =
    let
      cfg = config.services.ollama-stack;
    in
    lib.mkIf cfg.enable {
      services.ollama."ollama" = {
        imports = [ cfg.extraOllamaConfig ];
        enable = true;
        host = "0.0.0.0";
        models = [ "llama2-uncensored" ];
      };
      settings = lib.optionalAttrs (cfg.open-webui.enable) {
        processes.open-webui =
          let
            ollama-cfg = config.services.ollama.ollama;
          in
          {
            command = pkgs.writeShellApplication {
              name = "open-webui";
              runtimeInputs = [ self'.packages.open-webui-backend.pyEnv ];
              text = ''
                set -x
                # TODO: make a service and give it a dataDir option
                if [ -d ./data/open-webui ]; then
                  rm -rf ./data/open-webui
                fi
                mkdir -p ./data/open-webui/build
                cp -r ${inputs.open-webui}/. ./data/open-webui
                # There is FRONTEND_BUILD_DIR, but backend is hardcoded to find some components of the frontend in the parent directory, like the favicon in `backend/config.py`
            
                cp -r ${pkgs.open-webui-frontend}/share/open-webui/. ./data/open-webui/build
                chmod -R u+rw ./data/open-webui
                cd ./data/open-webui/backend

                # TODO: protocol must be an option
                OLLAMA_API_BASE_URL=http://${ollama-cfg.host}:${builtins.toString ollama-cfg.port}/api
                export OLLAMA_API_BASE_URL
                uvicorn main:app --host 0.0.0.0 --port 1111 --forwarded-allow-ips '*'
              '';
            };
            readiness_probe = {
              http_get = {
                # TODO: wire the host and port config after open-webui is extracted to be a service
                host = "0.0.0.0";
                port = 1111;
              };
              initial_delay_seconds = 2;
              period_seconds = 10;
              timeout_seconds = 4;
              success_threshold = 1;
              failure_threshold = 5;
            };
            depends_on."ollama-models".condition = "process_completed_successfully";
          };

        processes.open-browser = {
          command = pkgs.writeShellApplication {
            name = "open-browser";
            runtimeInputs = if pkgs.stdenv.isLinux then [ pkgs.xdg-utils ] else [ ];
            # TODO: wire the host and port config after open-webui is extracted to be a service
            text = ''
              ${ if pkgs.stdenv.isLinux then "xdg-open http://0.0.0.0:1111" else "" }
              ${ if pkgs.stdenv.isDarwin then "open http://0.0.0.0:1111" else "" }
            '';
          };
          depends_on."open-webui".condition = "process_healthy";
        };
      };
    };
}
