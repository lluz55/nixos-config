{ nixpkgs, lib, system, ... }:
let
  pkgs = import nixpkgs {
    inherit system;
    config = {
      android_sdk.accept_license = true;
      allowUnfree = true;
    };
  };
  buildToolsVersion = "33.0.2";
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    buildToolsVersions = [ buildToolsVersion "28.0.3" ];
    platformVersions = [ "33" ];
    abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
  };
  androidSdk = androidComposition.androidsdk;
in
with lib; {
  devShells = {
    default = with pkgs; mkShell {
      buildInputs = [ cowsay ];
    };
    flutter = with pkgs; mkShell {
      ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
      buildInputs = [
        flutter
        androidSdk
        jdk17
      ];
    };
  };
}
