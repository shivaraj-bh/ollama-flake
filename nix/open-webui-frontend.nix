{ inputs }:
{ lib
, buildNpmPackage
, fetchFromGitHub
}:
buildNpmPackage rec {
  pname = "open-webui-frontend";
  version = "0.1.114";

  src = inputs.open-webui;

  npmDepsHash = "sha256-nTF5tBMiSVxROI86EF6edlLRpufLyA90mzw1JAzl0Hk=";

  npmBuildScript = "build";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share
    cp -a build $out/share/open-webui

    runHook postInstall
  '';

  meta = with lib; {
    description = "User-friendly WebUI for LLMs (Formerly Ollama WebUI)";
    homepage = "https://github.com/open-webui/open-webui";
    license = licenses.mit;
    mainProgram = pname;
    platforms = platforms.linux ++ platforms.darwin;
  };
}

