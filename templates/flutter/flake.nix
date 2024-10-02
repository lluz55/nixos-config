{
  description = "Flutter 3.13.x";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };
        buildToolsVersion = "34.0.0";
        # buildToolsVersion = "33.0.2";
        androidComposition = pkgs.androidenv.composeAndroidPackages {
          buildToolsVersions = [ buildToolsVersion "34.0.0" ];
          # buildToolsVersions = [ buildToolsVersion "28.0.3" ];
          platformVersions = [ "34" ];
          abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
        };
        androidSdk = androidComposition.androidsdk;
      in
      {
        devShell =
          with pkgs; mkShell rec {
            ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
            buildInputs = [
              flutter
              androidSdk
              jdk17
            ];
          };
      });
}
{
  description = "Flutter 3.13.x";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flutter-nix.url = "github:maximoffua/flutter.nix/stable";
  };
  outputs = { self, nixpkgs, flake-utils, flutter-nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
          overlays = [
            flutter-nix.overlays.default
          ];
        };
        buildToolsVersion = "34.0.0";
        androidComposition = pkgs.androidenv.composeAndroidPackages {
          buildToolsVersions = [ buildToolsVersion "28.0.3"];
          platformVersions = [ "34" ];
          abiVersions = [ "arm64-v8a" ];
          # TODO: Based on:
          # https://github.com/SharezoneApp/sharezone-app/blob/ca90027f6988c068ca08087c865575c980fc0a8f/devenv.nix
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
            FLUTER_SDK = "${flutter}/bin/flutter";
            shellHook = ''
              export CHROME_EXECUTABLE=/run/current-system/sw/bin/google-chrome-stable
              export PATH="$PATH":"$HOME/.pub-cache/bin:$HOME/.cargo/bin"
              export FLUTTER_ROOT="${pkgs.flutter}"
           '';

            buildInputs = [
              flutter
              androidSdk
              jdk17
            ];
            
          };
      });
}


