{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    rust-overlay.url = "github:oxalica/rust-overlay";
    # crane.url = "github:ipetkov/crane";
    # crane.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      perSystem = { config, self', pkgs, lib, system, ... }:
        let
          rustToolchain = pkgs.rust-bin.stable.latest.default.override {
            extensions = [
              "rust-src"
              "rust-analyzer"
              "clippy"
            ];
          };
          commom = with pkgs; [        
            openssl
            glib
            gtk3
            libsoup_3
            webkitgtk_4_1
            pkg-config
          ];
          rustBuildInputs = with pkgs; [
            libiconv
          ] ++ lib.optionals pkgs.stdenv.isLinux [
            xdotool
          ];
          tauriNativeBuildInputs = with pkgs; [
            pkg-config
            gobject-introspection
            cargo
            cargo-tauri
            nodejs
            clang
          ];
          tauriBuildInputs = with pkgs; [
            cairo
            atkmm
            pango
            gdk-pixbuf
            dbus
            librsvg
            harfbuzz
            at-spi2-atk
          ];
          packages = with pkgs; [
            vscodium
            cargo-tauri
            curl
            wget
            pnpm
          ];

          buildInputs = rustBuildInputs ++ tauriBuildInputs ++ packages ++ commom;
          # This is useful when building crates as packages
          # Note that it does require a `Cargo.lock` which this repo does not have
          # craneLib = (inputs.crane.mkLib pkgs).overrideToolchain rustToolchain;
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              inputs.rust-overlay.overlays.default
            ];
          };

          devShells.default = pkgs.mkShell {
            name = "Tauri + Dioxus Dev";
            buildInputs = buildInputs;
            nativeBuildInputs = [
              # Add shell dependencies here
              rustToolchain
              tauriNativeBuildInputs              
            ];
            shellHook = ''
              # For rust-analyzer 'hover' tooltips to work.
              export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath buildInputs}:$LD_LIBRARY_PATH
              export XDG_DATA_DIRS=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS

            '';
          };
        };
    };
}
