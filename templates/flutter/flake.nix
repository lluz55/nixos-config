{
  description = "Flutter";
  inputs = {
      # nixpkgs-unstable.url = "github:NixOS/nixpkgs/master";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs-unstable, flake-utils,  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs-unstable {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };
        buildToolsVersion = "34.0.0";
        androidComposition = pkgs.androidenv.composeAndroidPackages {
          buildToolsVersions = [ buildToolsVersion "28.0.3"];
          platformVersions = [ "34" ];
          abiVersions = [ "arm64-v8a" ];
          extraLicenses = [
            "android-googletv-license"
            "android-sdk-arm-dbt-license"
            "android-sdk-license"
            "android-sdk-preview-license"
            "google-gdk-license"
            "intel-android-extra-license"
            "intel-android-sysimage-license"
            "mips-android-sysimage-license"
          ];
        };
        androidSdk = androidComposition.androidsdk;
      in
      {
        devShell =
          with pkgs; mkShell rec {
            ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
            FLUTTER_SDK = "${pkgs.flutter}/bin/flutter";
            # FLUTER_SDK = "${flutter}/bin/flutter";
            shellHook = ''
              export CHROME_EXECUTABLE=/run/current-system/sw/bin/google-chrome-stable
              export PATH="$PATH":"$HOME/.pub-cache/bin:$HOME/.cargo/bin"
              export FLUTTER_ROOT="${pkgs.flutter}"
            '';
            buildInputs = [
              flutter
              dart
              androidSdk
              jdk17
            ];
          };
      });
}
