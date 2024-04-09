inputs:
{ lib
, buildNpmPackage
, fetchFromGitHub
, open-webui-backend-env
, writeShellApplication
, mktemp
}:
let
  frontend = buildNpmPackage {
    pname = "open-webui-frontend";
    version = "0.2";

    src = inputs.open-webui;

    npmDepsHash = "sha256-VW89XnzputCWw5dOAKg09kve7IMNlxGS6ShYEo1ZC7s=";

    npmBuildScript = "build";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share
      cp -a build $out/share/open-webui

      runHook postInstall
    '';

    meta = with lib; {
      description = "Frontend of open-webui. open-webui is a user-friendly WebUI for LLMs (Formerly Ollama WebUI)";
      homepage = "https://github.com/open-webui/open-webui";
      license = licenses.mit;
      platforms = platforms.linux ++ platforms.darwin;
    };
  };
in
writeShellApplication {
  name = "open-webui";
  runtimeInputs = [ open-webui-backend-env mktemp ];
  runtimeEnv = {
    FRONTEND_BUILD_DIR = "${frontend}/share/open-webui";
  };
  text = ''
    if [ -z "$DATA_DIR" ]; then
      DATA_DIR=$(mktemp -d)
      STATIC_DIR=$DATA_DIR/static

      mkdir -p "$STATIC_DIR"

      export DATA_DIR STATIC_DIR
    fi

    if [ -z "$WEBUI_PORT" ]; then
      WEBUI_PORT=8080
      export WEBUI_PORT
    fi

    if [ -z "$WEBUI_HOST" ]; then
      WEBUI_HOST=localhost
      export WEBUI_HOST
    fi

    cd ${inputs.open-webui}/backend
    uvicorn main:app --host "$WEBUI_HOST" --port "$WEBUI_PORT" --forwarded-allow-ips '*' 
  '';
  meta = with lib; {
    description = "Full-stack of open-webui. open-webui is a user-friendly WebUI for LLMs (Formerly Ollama WebUI)";
    homepage = "https://github.com/open-webui/open-webui";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
  };
}
