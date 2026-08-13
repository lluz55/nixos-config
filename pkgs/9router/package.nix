{ writeShellApplication, nodejs }:

writeShellApplication {
  name = "9router";
  runtimeInputs = [ nodejs ];
  text = ''
    exec npx -y 9router "$@"
  '';

  meta = {
    description = "9Router CLI runner using npx";
    mainProgram = "9router";
  };
}
