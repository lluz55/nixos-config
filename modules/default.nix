{ inputs
, pkgs
, unstable
, options
, ...
}: {
  imports = [
    ./options.nix
    ./desktops
    ./shell
    ./home-automation
    ./tools
    ./twingate.nix

    inputs.vscode-server.nixosModules.default
  ];

  programs.nix-ld.enable = true;

  programs.nix-ld.libraries = options.programs.nix-ld.libraries.default ++ (with pkgs;
    [
      rust-analyzer
      luajitPackages.luarocks # needed?
      stylua # needed?
      ast-grep
      lua-language-server
      python3
      glibc
    ]);

  environment.systemPackages = with pkgs; [
    killall
    nmap
    lazygit
    htop
    neovim-nightly
    ripgrep
    nil
    lua-language-server
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
  ] ++ (with unstable; [
    helix
  ]);
}
