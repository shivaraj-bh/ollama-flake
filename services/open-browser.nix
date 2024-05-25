{ pkgs, lib, config, ... }:
let
  inherit (lib) types;
  cfg = config.services.open-browser;
in
{
  options.services.open-browser = {
    enable = lib.mkEnableOption "private-gpt for local large language models";

    host = lib.mkOption {
      type = types.str;
      default = "localhost";
      description = ''
        Host of the website to open in the browser.
      '';
    };

    port = lib.mkOption {
      type = types.port;
      default = 8080;
      description = ''
        Port of the website to open in the browser.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    settings.processes = {
      open-browser = {
        command = pkgs.writeShellApplication {
          name = "open-browser";
          runtimeInputs = if pkgs.stdenv.isLinux then [ pkgs.xdg-utils ] else [ ];
          text = ''
            ${ if pkgs.stdenv.isLinux then "xdg-open http://${cfg.host}:${builtins.toString cfg.port}" else "" }
            ${ if pkgs.stdenv.isDarwin then "open http://${cfg.host}:${builtins.toString cfg.port}" else "" }
          '';
        };
      };
    };
  };
}
