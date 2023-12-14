{ pkgs, inputs, config, master-user, ... }:

{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops.defaultSopsFile = ../secrets/all_secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  sops.age.keyFile = "/home/${master-user.name}/.config/sops/age/keys.txt";

  sops.secrets.frigate = {
    owner = master-user.name;
  };
  sops.secrets.mqtt = {
    owner = master-user.name;
  };

  environment.systemPackages = with pkgs; [
    sops
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
