{
  inputs = {
  
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    android.url = "github:tadfisher/android-nixpkgs";
    android.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    rust.url = "github:oxalica/rust-overlay";
    rust.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, rust,... } @inputs: 
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system}.extend rust.overlays.default;
        rust-pkg = pkgs.rust-bin.selectLatestNightlyWith (
          toolchain:
          toolchain.default.override {
            extensions = [
              "rust-analyzer"
              "rust-src"
            ];
            targets = [
              "aarch64-linux-android"
              "armv7-linux-androideabi"
              "i686-linux-android"
              "x86_64-linux-android"
            ];
          }
        );
         android-sdk = inputs.android.sdk.${system} (
          sdkPkgs: with sdkPkgs; [
            cmdline-tools-latest
            cmake-3-22-1
            build-tools-34-0-0
            build-tools-35-0-0
            platform-tools
            platforms-android-35
            emulator
            system-images-android-35-google-apis-x86-64
            ndk-26-1-10909125
          ]
        );

        java-jdk = pkgs.jdk17;

        libraries = with pkgs;[
          webkitgtk
          gtk3
          cairo
          gdk-pixbuf
          glib
          dbus
          openssl
          librsvg
        ];

        build_inputs = with pkgs; [
          curl
          wget
          pkg-config
          dbus
          openssl
          glib
          gtk3
          libsoup
          webkitgtk_4_1
          librsvg
          cargo-tauri
          typescript-language-server
          nodejs_23
        ];
      in
      {
        packages.default = self.packages.createEmulateTauri;
        devShell = pkgs.mkShell rec{
          buildInputs = build_inputs;
          packages = with pkgs;[
            self.packages.${system}.createAndEmulateTauri
            android-sdk
            rust-pkg
            java-jdk
          ] ++ (with pkgs; [
            nodejs_18
            watchman
            aapt
            cargo-ndk
            typescript-language-server
          ]);
          shellHook =
            ''
              export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath libraries}:$LD_LIBRARY_PATH
              export XDG_DATA_DIRS=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS
            '';
        };
        
        packages.createAndEmulateTauri = pkgs.writeScriptBin "create-and-emulate-tauri-app" ''
          #!/usr/bin/env sh
          date=$(date +%s)
          avd=myavd$date
          echo "using date $date"
          mkdir -p demo-app-$date/avds
          export ANDROID_AVD_HOME=$HOME/.config/.android/avd
          echo using $ANDROID_AVD_HOME as ANDROID_AVD_HOME
          echo "no" | avdmanager create avd -k 'system-images;android-35;google_apis;x86_64' -n $avd
          #cd demo-app-$date
          #echo "demo-app" | yarn create expo-app
          #cd demo-app
          #yarn expo install expo-dev-client
          #yarn expo run:android -d $avd
        '';
      });
}
