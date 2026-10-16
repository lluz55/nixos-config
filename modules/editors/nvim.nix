{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = false;
    viAlias = true;
    vimAlias = true;
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "neovim" ''
      exec nvim "$@"
    '')
  ];
}