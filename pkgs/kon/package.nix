{ lib
, python3Packages
, fetchurl
, autoPatchelfHook
, stdenv
}:
let
  # Não está no nixpkgs. Extensão nativa (Rust/abi3), sem dependências Python
  # próprias — empacotada a partir da wheel manylinux pré-compilada.
  html-to-markdown = python3Packages.buildPythonPackage rec {
    pname = "html-to-markdown";
    version = "3.3.1";
    format = "wheel";

    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/1a/58/49a06a6460be618f73da36acb9428a10b28712b4f5447b18f7e76882be64/html_to_markdown-3.3.1-cp310-abi3-manylinux2014_x86_64.manylinux_2_17_x86_64.whl";
      hash = "sha256-9Fy6tvZb4zFF3RUt894Lr3yVQl294Gg0+5RxDb4bG6c=";
    };

    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [ stdenv.cc.cc.lib ];

    doCheck = false;
    pythonImportsCheck = [ "html_to_markdown" ];
  };
in
python3Packages.buildPythonApplication rec {
  pname = "kon-coding-agent";
  version = "0.4.2";
  pyproject = true;

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/65/ed/41bfda77edc07b6ff6a299d73c5271a870ff9cfa7ec9623996ac73753e90/kon_coding_agent-0.4.2.tar.gz";
    hash = "sha256-+WzswhPWCZzVkC66CMYQSth+s+tFxvjumPcI99OkuBA=";
  };

  build-system = [ python3Packages.hatchling ];

  dependencies = with python3Packages; [
    aiofiles
    aiohttp
    anthropic
    curl-cffi
    ddgs
    html-to-markdown
    lxml-html-clean
    openai
    pillow
    pydantic
    readability-lxml
    rich
    textual
  ];

  # sdist não traz suíte de testes; import-check garante que as deps batem.
  doCheck = false;
  pythonImportsCheck = [ "kon" ];

  meta = {
    description = "Minimal terminal-based coding agent";
    homepage = "https://github.com/0xku/kon";
    license = lib.licenses.mit;
    mainProgram = "kon";
    platforms = [ "x86_64-linux" ];
  };
}
