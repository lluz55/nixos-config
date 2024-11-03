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

  sops.defaultSopsFile = ../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  sops.age.keyFile = "/home/${masterUser.name}/.config/sops/age/keys.txt";
  sops.secrets."twingate.env" = {};
  sops.secrets."frigate.env" = {};
  sops.secrets."mqtt.env" = {};
  sops.secrets."macs/poco" = {};
  sops.secrets."macs/gl62m" = {};
  sops.secrets."macs/b450" = {};
  sops.secrets."macs/rn10c" = {};
  sops.secrets."macs/honor" = {};
  sops.secrets."macs/mibox2" = {};
  sops.secrets."macs/tabs5e" = {};
  sops.secrets."macs/a55" = {};

  security = {
    polkit = {
      enable = true;
      extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (subject.isInGroup("wheel")) {
            return polkit.Result.YES;
          }
        });
        '';
    };
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
      extra-substituters = [ "https://cosmic.cachix.org/" "https://nix-community.cachix.org"];
      extra-trusted-substituters = [ "https://cosmic.cachix.org/" "https://nix-community.cachix.org"];
      trusted-public-keys = [
         "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
         "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    package = pkgs.nixVersions.latest;
    registry.nixpkgs.flake = inputs.nixpkgs;
  };
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "23.11";
}

