{ pkgs
, unstable
, ...
}:
{
  environment.systemPackages = [
    unstable.helix
    (pkgs.writeShellScriptBin "helix" ''
      exec hx "$@"
    '')
  ];
}
