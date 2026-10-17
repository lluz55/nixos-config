{ pkgs
, unstable
, ...
}: {
  imports = [
    ./desktops
    ./profiles
    ./wayland.nix
    ./waydroid
    ./shell
    ./home-automation
    ./tools
    ./twingate.nix
    ./virt.nix
    ./editors
    ./hyprland/core.nix
    ./waybar/waybar.nix
    ./servers
    ./hardware/nvidia.nix
    ./hardware/printing.nix
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    glibc
    openssl
    curl
  ];

  environment.sessionVariables = {
    OPENCODE_ENABLE_EXA = "1";
  };

  # Pacotes pessoais e interativos são geridos pelo Home Manager. Este módulo
  # mantém apenas utilitários que ainda são dependências de serviços NixOS ou
  # ferramentas administrativas sem equivalente no perfil do usuário.
  environment.systemPackages = with unstable; [
    p7zip
    htop
    killall
    (
      let
        base = pkgs.appimageTools.defaultFhsEnvArgs;
      in
      pkgs.buildFHSEnv (base
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
