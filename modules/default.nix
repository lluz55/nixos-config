{ inputs, pkgs, ... }:
{
  imports = [
    ./options.nix
    ./desktops
    ./shell
    ./homeassistant
    ./frigate
    ./tools

    inputs.vscode-server.nixosModules.default
  ];

  environment.systemPackages = with pkgs; [
    killall
    nmap
    lazygit
    htop
    (
      let
        base = pkgs.appimageTools.defaultFhsEnvArgs;
      in
      pkgs.buildFHSUserEnv (base
        // {
        name = "fhs";
        targetPkgs = pkgs: (base.targetPkgs pkgs) ++ [ pkgs.pkg-config ];
        profile = "export FHS=1";
        runScript = "bash";
        extraOutputsToInstall = [ "dev" ];
      })
    )
  ];
}
