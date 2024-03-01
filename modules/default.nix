{
  inputs,
  pkgs,
  unstable,
  ...
}: {
  imports = [
    ./options.nix
    ./desktops
    ./shell
    ./home-automation
    ./tools
    ./twingate.nix
    ./virt.nix
    ./editors/nixvim
    inputs.vscode-server.nixosModules.default
  ];

  # programs.nix-ld.enable = true;
  # programs.nix-ld.libraries = options.programs.nix-ld.libraries.default ++ (with pkgs;
  #   [
  #     rust-analyzer
  #     luajitPackages.luarocks # needed?
  #     stylua # needed?
  #     ast-grep
  #     lua-language-server
  #     python3
  #     glibc
  #   ]);

  environment.systemPackages = with unstable;
    [
      # PS2 Emulator
      #pcsx2

      # Terminal tools
      p7zip
      htop
      killall
      ripgrep
      zoxide
      sd
      broot

      # Git
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
          pkgs.buildFHSUserEnv (base
            // {
              name = "fhs";
              targetPkgs = pkgs: (base.targetPkgs pkgs) ++ [pkgs.pkg-config];
              profile = "export FHS=1";
              runScript = "bash";
              extraOutputsToInstall = ["dev"];
            })
      )
    ]
    ++ (with pkgs; [
      # Deveolpment tools
      neovim-nightly
    ]);
}
