{ writeShellApplication, uv, git, coreutils, bash, python313, runCommand }:

let
  houndRunner = writeShellApplication {
    name = "hound";
    runtimeInputs = [ uv git coreutils bash python313 ];
    text = ''
      export UV_PYTHON_DOWNLOADS=never
      export UV_PYTHON="${python313}/bin/python3"

      exec uvx --from "hound-mcp[all]" hound "$@"
    '';

    meta = {
      description = "Hound MCP - Web research for AI agents";
      mainProgram = "hound";
    };
  };
in
runCommand "hound-mcp" {
  meta = houndRunner.meta // {
    mainProgram = "hound";
  };
} ''
  mkdir -p $out/bin
  ln -s ${houndRunner}/bin/hound $out/bin/hound
  ln -s ${houndRunner}/bin/hound $out/bin/hound-mcp
''
