{ lib, ... }:
with lib; {
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
      echo -n (date +%H:%M) (prompt_pwd)
      zoxide init fish | source
      starship init fish | source
    '';
    shellAliases = mkForce {
      ## Git aliases
      ga = "git add ";
      gaa = "git add .";
      gp = "git push";
      gpl = "git pull";
      gcm = "git commit -m";
      gd = "git diff";
      glog = "git log --oneline";
      gc = "git checkout ";
      gst = "git status";
      gamend = "git commit --amend";
      gamendn = "git commit --amend --no-edit";

      v = "nvim";

      nvf = "nix run github:notashelf/neovim-flake#maximal -- ";

      # Power related
      sdn = "shutdown now";
      sdr = "shutdown -r now";

      c = "clear";

      # Zig
      zbr = "zig build run";

      # Changing "ls" to "exa"
      ls = "exa --icons --color=always --group-directories-first";
      lll = "exa -lF --icons --color=always --group-directories-first";
      ll = "exa -alF --icons --color=always --group-directories-first";
      la = "exa -a --icons --color=always --group-directories-first";
      l = "exa -F --icons --color=always --group-directories-first";
    };
  };
}
