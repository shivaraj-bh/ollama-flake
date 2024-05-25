{ pkgs, lib, config, ... }:
let
  inherit (lib) types;
  cfg = config.services.open-webui;
in
{
  options.services.open-webui = {
    enable = lib.mkEnableOption "Enable open-webui, an interactive chat web app";
    port = lib.mkOption {
      type = types.int;
      default = 1111;
      description = ''
        Port for open-webui.
      '';
    };
    host = lib.mkOption {
      type = types.str;
      default = "localhost";
      description = ''
        Host for open-webui.
      '';
    };
    dataDir = lib.mkOption {
      type = types.str;
      default = "./data/open-webui";
      description = ''
        Data directory for open-webui.
      '';
    };
    ollamaHost = lib.mkOption {
      type = types.str;
      default = "localhost";
      description = ''
        Hostname for ollama service.
      '';
    };
    ollamaPort = lib.mkOption {
      type = types.int;
      default = 11434;
      description = ''
        Port for ollama service.
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    settings.processes = {
      open-webui = {
        command = pkgs.writeShellApplication {
          name = "open-webui-wrapper";
          runtimeInputs = [ pkgs.open-webui ];
          runtimeEnv = {
            OLLAMA_API_BASE_URL = "http://${cfg.ollamaHost}:${builtins.toString cfg.ollamaPort}/api";
            WEBUI_PORT = "${builtins.toString cfg.port}";
            WEBUI_HOST = cfg.host;
          };
          text = ''
            set -x
            if [ ! -d ${cfg.dataDir} ]; then
              mkdir -p ${cfg.dataDir} 
            fi

            DATA_DIR=$(readlink -f ${cfg.dataDir})
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
            host = cfg.host;
            port = cfg.port;
          };
          initial_delay_seconds = 2;
          period_seconds = 10;
          timeout_seconds = 4;
          success_threshold = 1;
          failure_threshold = 5;
        };
      };

      open-browser.depends_on."open-webui".condition = "process_healthy";
    };
    services.open-browser = {
      enable = true;
      inherit (cfg) host port;
    };
  };
}
