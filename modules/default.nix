{ inputs
, pkgs
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

  environment.systemPackages = with unstable;
    [
      # PS2 Emulator
      #pcsx2

      neovim

      # Terminal tools
      p7zip
      htop
      killall
      ripgrep
      zoxide
      sd
      broot
      dust

      # Git
      gh
      lazygit

      # Network tools
      nmap

      # Development tools
      nil
      lua-language-server
      helix
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
    ]
    ++ (with pkgs; [
      # Deveolpment tools
      #neovim-nightly
    ]);
}
