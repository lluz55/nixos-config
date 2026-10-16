{ writeShellApplication, uv, git, coreutils, bash, python313, runCommand }:

let
  version = "13.2.0";

  houndRunner = writeShellApplication {
    name = "hound";
    runtimeInputs = [ uv git coreutils bash python313 ];
    text = ''
      export UV_PYTHON_DOWNLOADS=never
      export UV_PYTHON="${python313}/bin/python3"

      exec uvx --from "hound-mcp[all]==${version}" hound "$@"
    '';

    meta = {
      description = "Hound MCP - Web research for AI agents";
      mainProgram = "hound";
    };
  };
in
runCommand "hound-mcp-${version}" {
  inherit version;
  meta = houndRunner.meta // {
    mainProgram = "hound";
  };
} ''
  mkdir -p $out/bin
  ln -s ${houndRunner}/bin/hound $out/bin/hound
  ln -s ${houndRunner}/bin/hound $out/bin/hound-mcp
''
