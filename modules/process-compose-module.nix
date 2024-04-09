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
                port = lib.mkOption {
                  type = lib.types.int;
                  default = 1111;
                  description = ''
                    Port for open-webui.
                  '';
                };
                host = lib.mkOption {
                  type = lib.types.str;
                  default = "0.0.0.0";
                  description = ''
                    Host for open-webui.
                  '';
                };
                dataDir = lib.mkOption {
                  type = lib.types.str;
                  default = "./data/open-webui";
                  description = ''
                    Data directory for open-webui.
                  '';
                };
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
                OLLAMA_API_BASE_URL = "http://${ollama-cfg.host}:${builtins.toString ollama-cfg.port}/api";
                WEBUI_PORT = "${builtins.toString cfg.open-webui.port}";
                WEBUI_HOST = cfg.open-webui.host;
              };
              text = ''
                set -x
                if [ ! -d ${cfg.open-webui.dataDir} ]; then
                  mkdir -p ${cfg.open-webui.dataDir} 
                fi

                DATA_DIR=$(readlink -f ${cfg.open-webui.dataDir})
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
                host = cfg.open-webui.host;
                port = cfg.open-webui.port;
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
            text = ''
              ${ if pkgs.stdenv.isLinux then "xdg-open http://${cfg.open-webui.host}:${builtins.toString cfg.open-webui.port}" else "" }
              ${ if pkgs.stdenv.isDarwin then "open http://${cfg.open-webui.host}:${builtins.toString cfg.open-webui.port}" else "" }
            '';
          };
          depends_on."open-webui".condition = "process_healthy";
        };
      };
    };
}
