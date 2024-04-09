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
              name = "open-webui-wrapper";
              runtimeInputs = [ pkgs.open-webui ];
              runtimeEnv = {
                # TODO: protocol must be an option
                OLLAMA_API_BASE_URL = "http://${ollama-cfg.host}:${builtins.toString ollama-cfg.port}/api";
                WEBUI_PORT = "1112";
                WEBUI_HOST = "0.0.0.0";
              };
              text = ''
                set -x
                # TODO: make a service and give it a dataDir option
                if [ ! -d ./data/open-webui ]; then
                  mkdir -p ./data/open-webui
                fi

                DATA_DIR=$(readlink -f ./data/open-webui)
                STATIC_DIR=$DATA_DIR/static

                if [ ! -d "$STATIC_DIR" ]; then
                  mkdir -p "$STATIC_DIR"
                fi

                export DATA_DIR STATIC_DIR

                open-webui
              '';
            };
            readiness_probe = {
              http_get = {
                # TODO: wire the host and port config after open-webui is extracted to be a service
                host = "0.0.0.0";
                port = 1112;
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
              ${ if pkgs.stdenv.isDarwin then "open http://0.0.0.0:1112" else "" }
            '';
          };
          depends_on."open-webui".condition = "process_healthy";
        };
      };
    };
}
