{ config
, lib
, pkgs
, unstable
, waydroidsu
, ...
}:
with lib;
let
  cfg = config.waydroid;

  scriptRuntimeInputs = [
    cfg.package
    pkgs.coreutils
    pkgs.curl
    pkgs.gawk
    pkgs.git
    pkgs.gnugrep
    pkgs.gnused
    pkgs.lzip
    pkgs.nix
    pkgs.python3
    pkgs.sqlite
    pkgs.sudo
    pkgs.systemd
  ];

  scriptPackage = pkgs.stdenvNoCC.mkDerivation {
    pname = "waydroid-maintenance-scripts";
    version = "1";
    src = ../../scripts;
    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share/doc/waydroid-maintenance-scripts

      install -Dm755 install-magisk.sh $out/bin/waydroid-install-magisk
      install -Dm755 install-zygisk-next.sh $out/bin/waydroid-install-zygisk-next
      install -Dm755 install-play-integrity-fix.sh $out/bin/waydroid-install-play-integrity-fix
      install -Dm755 install-tricky-store.sh $out/bin/waydroid-install-tricky-store
      install -Dm755 configure-tricky-store.sh $out/bin/waydroid-configure-tricky-store
      install -Dm755 helper-play-integrity.sh $out/bin/waydroid-play-integrity-helper
      install -Dm755 install-arm.sh $out/bin/waydroid-install-arm-translation
      install -Dm644 README.md $out/share/doc/waydroid-maintenance-scripts/README.md

      substituteInPlace $out/bin/waydroid-install-magisk \
        --replace-fail 'WSU_PATH=$(nix build "$REPO_DIR#waydroidsu" --no-link --print-out-paths)' 'WSU_PATH=${waydroidsu}'

      substituteInPlace $out/bin/waydroid-play-integrity-helper \
        --replace-fail '"$SCRIPT_DIR/install-zygisk-next.sh"' "$out/bin/waydroid-install-zygisk-next" \
        --replace-fail '"$SCRIPT_DIR/install-play-integrity-fix.sh"' "$out/bin/waydroid-install-play-integrity-fix" \
        --replace-fail '"$SCRIPT_DIR/install-tricky-store.sh"' "$out/bin/waydroid-install-tricky-store" \
        --replace-fail '"$SCRIPT_DIR/configure-tricky-store.sh"' "$out/bin/waydroid-configure-tricky-store"

      for script in $out/bin/waydroid-*; do
        wrapProgram "$script" \
          --prefix PATH : ${lib.makeBinPath scriptRuntimeInputs}
      done

      runHook postInstall
    '';
  };
in
{
  options.waydroid = {
    enable = mkEnableOption "Waydroid with local maintenance scripts";

    package = mkOption {
      type = types.package;
      default = unstable.waydroid-nftables;
      description = mdDoc "Waydroid package to use for the container and helper scripts.";
    };

    scripts.enable = mkOption {
      type = types.bool;
      default = true;
      description = mdDoc "Install Waydroid Magisk, Zygisk, Play Integrity, Tricky Store and ARM translation helper scripts.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.waydroid = {
      enable = true;
      package = cfg.package;
    };

    environment.systemPackages =
      [
        cfg.package
        unstable.waydroid-helper
        waydroidsu
      ]
      ++ optional cfg.scripts.enable scriptPackage;
  };
}
