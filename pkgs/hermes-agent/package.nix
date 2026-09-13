{
  lib,
  python313Packages,
  fetchPypi,
  git,
  ripgrep,
}:

# Hermes Agent (Nous Research) é distribuído no PyPI como wheel puro. As deps
# do projeto vêm pinadas com `==`; aqui elas são relaxadas para as versões do
# nixpkgs (pythonRelaxDeps). Extras "cli", "mcp" e "web" são incluídos porque
# são o que o uso interativo no terminal realmente exercita.
python313Packages.buildPythonApplication rec {
  pname = "hermes-agent";
  version = "0.19.0";
  format = "wheel";

  src = fetchPypi {
    pname = "hermes_agent";
    inherit version format;
    dist = "py3";
    python = "py3";
    hash = "sha256-vQusASruOKYIlHgfRZfcKe577bNEhUAkmSHxDTvvMn8=";
  };

  pythonRelaxDeps = true;

  nativeBuildInputs = [ python313Packages.pythonRelaxDepsHook ];

  dependencies = with python313Packages; [
    openai
    certifi
    python-dotenv
    fire
    httpx
    socksio
    rich
    tenacity
    pyyaml
    ruamel-yaml
    requests
    jinja2
    pydantic
    prompt-toolkit
    croniter
    packaging
    markdown
    pyjwt
    urllib3
    cryptography
    psutil
    websockets
    pathspec
    fastapi
    uvicorn
    python-multipart
    ptyprocess
    pillow
    # extras
    simple-term-menu
    mcp
    starlette
    aiohttp
  ];

  makeWrapperArgs = [ "--suffix PATH : ${lib.makeBinPath [ git ripgrep ]}" ];

  # O pacote não embarca suíte de testes utilizável fora do repo.
  doCheck = false;

  pythonImportsCheck = [ "hermes_cli" ];

  meta = {
    description = "Hermes Agent — assistente/agente de IA em CLI da Nous Research";
    homepage = "https://github.com/NousResearch/Hermes-Agent";
    downloadPage = "https://pypi.org/project/hermes-agent/";
    license = lib.licenses.mit;
    mainProgram = "hermes";
    platforms = lib.platforms.unix;
  };
}
