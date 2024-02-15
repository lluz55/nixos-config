{
  pkgs,
  inputs,
  masterUser,
  ...
}: {
  time.timeZone = "America/Recife";
  i18n = {
    defaultLocale = "pt_BR.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "pt_BR.UTF-8";
      LC_MONETARY = "pt_BR.UTF-8";
    };
  };

  security = {
    polkit.enable = true;
    rtkit.enable = true;
  };

  fonts.packages = with pkgs; [
    fira-code
    font-awesome
    (nerdfonts.override {
      fonts = [
        "JetBrainsMono"
      ];
    })
  ];

  environment = {
    variables = {
      TERMINAL = "${masterUser.terminal}";
      EDITOR = "${masterUser.editor}";
      VISUAL = "${masterUser.editor}";
    };
  };

  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;

  nix = {
    settings = {
      tarball-ttl = 0;
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    package = pkgs.nixVersions.unstable;
    registry.nixpkgs.flake = inputs.nixpkgs;
  };
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "23.11";
}
