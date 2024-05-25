{ pkgs, lib, config, ... }:
let
  inherit (lib) types;

  yamlFormat = pkgs.formats.yaml { };
  cfg = config.services.private-gpt;
in
{
  options = {
    services.private-gpt = {
      enable = lib.mkEnableOption "private-gpt for local large language models";

      package = lib.mkPackageOption pkgs "private-gpt" { };

      port = lib.mkOption {
        type = types.port;
        default = 8001;
        description = ''
          Port where private-gpt should listen on.
        '';
      };

      dataDir = lib.mkOption {
        type = types.str;
        default = "./data/private-gpt";
        description = "Data directory of private-gpt.";
      };

      extraSettings = lib.mkOption {
        type = yamlFormat.type;
        default = { };
        description = "Additional settings to override default settings-local.yaml";
        example = ''
          ollama = {
            llm_model = "llama3";
            embedding_model = "nomic-embed-text";
            api_base = "http://localhost:11434";
            embedding_api_base = "http://localhost:11434";
            keep_alive = "5m";
            tfs_z = 1;
            top_k = 40;
            top_p = 0.9;
            repeat_last_n = 64;
            repeat_penalty = 1.2;
            request_timeout = 120;
          };
        '';
      };

      defaultSettings = lib.mkOption {
        type = yamlFormat.type;
        internal = true;
        readOnly = true;
        default = {
          server = {
            env_name = "local";
          };
          llm = {
            mode = "ollama";
            tokenizer = "";
            max_new_tokens = 512;
            context_window = 8000;
            temperature = 0.1;
          };
          embedding = {
            mode = "ollama";
          };
          ollama = {
            llm_model = "llama3:8b";
            embedding_model = "nomic-embed-text";
            api_base = "http://localhost:11434";
            embedding_api_base = "http://localhost:11434";
            keep_alive = "5m";
            tfs_z = 1;
            top_k = 40;
            top_p = 0.9;
            repeat_last_n = 64;
            repeat_penalty = 1.2;
            request_timeout = 120;
          };
          vectorstore = {
            database = "qdrant";
          };
          qdrant = {
            path = "\${QDRANT_DIR}";
          };
          data = {
            local_data_folder = "\${DATA_DIR}";
          };
          openai = { };
          azopenai = { };
        };
        description = ''
          settings-local.yaml for private-gpt
        '';
      };
    };
  };
  config = lib.mkIf cfg.enable {
    settings.processes = {
      private-gpt-init = {
        command = pkgs.writeShellApplication {
          name = "private-gpt-init";
          text =
            let
              config = yamlFormat.generate "settings-local.yaml" (
                lib.recursiveUpdate cfg.defaultSettings cfg.extraSettings
              );
            in
            ''
              set -x

              ${lib.concatMapStrings (subdir: ''
                if [ ! -d ${cfg.dataDir}/${subdir} ]; then
                  mkdir -p ${cfg.dataDir}/${subdir}
                fi
              '') [ "" "tiktoken_cache" "settings" ]}
              
              # TODO: Use qdrant server as a service
              # If we let private-gpt handle qdrant, we will have to start fresh every time we restart the process-compose window.
              [ -d "${cfg.dataDir}/vectorstore/qdrant" ] && rm -rf ${cfg.dataDir}/vectorstore/qdrant

              ln -sf ${cfg.package.cl100k_base.tiktoken} ${cfg.dataDir}/tiktoken_cache/9b5ad71b2ce5302211f9c61530b329a4922fc6a4
              ln -sf ${pkgs.python3Packages.private-gpt}/${pkgs.python3.sitePackages}/private_gpt/settings.yaml ${cfg.dataDir}/settings/settings.yaml
              ln -sf "${config}" "${cfg.dataDir}/settings/settings-local.yaml"
            '';
        };
      };
      private-gpt = {
        command = pkgs.writeShellApplication {
          name = "private-gpt-wrapper";
          runtimeInputs = [ pkgs.private-gpt ];
          runtimeEnv = {
            PGPT_PROFILES = "local";
            PGPT_SETTINGS_FOLDER = "${cfg.dataDir}/settings";
            HF_HOME = "${cfg.dataDir}/huggingface";
            TRANSFORMERS_OFFLINE = "1";
            HF_DATASETS_OFFLINE = "1";
            MPLCONFIGDIR = "${cfg.dataDir}/matplotlib";
            PORT = cfg.port;
          };
          text = ''
            DATA_DIR=$(readlink -f ${cfg.dataDir})
            QDRANT_DIR=$(readlink -f ${cfg.dataDir})/vectorstore/qdrant
            export DATA_DIR QDRANT_DIR
            private-gpt
          '';
        };
        readiness_probe = {
          http_get = {
            host = "localhost";
            port = cfg.port;
          };
          initial_delay_seconds = 2;
          period_seconds = 10;
          timeout_seconds = 4;
          success_threshold = 1;
          failure_threshold = 5;
        };
        depends_on."private-gpt-init".condition = "process_completed_successfully";
      };
    };
  };
}
