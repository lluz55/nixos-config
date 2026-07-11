{
  inputs = {
    rust-overlay.url = "github:oxalica/rust-overlay";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self
    , nixpkgs-unstable
    , rust-overlay
    ,
    }:
    let
      overlays = [ (import rust-overlay) ];
      unstable = import nixpkgs-unstable {
        inherit system overlays;
      };

      system = "x86_64-linux";
      app = "game";

      rust = unstable.rust-bin.stable."1.60.0".default.override {
        extensions = [
          "rust-src"
        ];
      };
      rustPlatform = unstable.makeRustPlatform {
        cargo = rust;
        rustc = rust;
      };

      shellInputs = with unstable; [
        rust
        clang
        mold
        sccache
      ];
      appNativeBuildInputs = with unstable; [
        clang
        mold
        pkg-config
      ];
      appBuildInputs =
        appRuntimeInputs
        ++ (with unstable; [
          udev
          perl
          alsaLib
          vulkan-tools
          vulkan-headers
          vulkan-validation-layers
        ]);
      appRuntimeInputs = with unstable; [
        stdenv.cc.cc.lib
        vulkan-loader
        xorg.libXcursor
        xorg.libXi
        xorg.libX11
        xorg.libXrandr
        libxkbcommon
        udev
        alsaLib
        rust-analyzer
        wayland
      ];
    in
    {
      templates.default = {
        path = ./.;
        description = "Bevy game development template";
      };

      devShells.${system}.${app} = unstable.mkShell {
        nativeBuildInputs = appNativeBuildInputs;
        buildInputs = shellInputs ++ appBuildInputs;

        shellHook = ''
          export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${unstable.lib.makeLibraryPath appRuntimeInputs}"
          export RUSTC_WRAPPER="${unstable.sccache}/bin/sccache"
          export SCCACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/sccache"
          export CARGO_INCREMENTAL=1
        '';
      };
      devShell.${system} = self.devShells.${system}.${app};

      packages.${system}.${app} = rustPlatform.buildRustPackage {
        pname = app;
        version = "0.1.0";

        src = ./.;
        cargoSha256 = "sha256-lzs+8qAsBJ/ms/OppxnKfJChV9+xM0W/QRZGPn+9uv4=";

        nativeBuildInputs = appNativeBuildInputs;
        buildInputs = appBuildInputs;

        preCheck = ''
          export LD_LIBRARY_PATH="${unstable.lib.makeLibraryPath appRuntimeInputs}:$LD_LIBRARY_PATH"
        '';

        postInstall = ''
          cp -r assets $out/bin/
        '';
      };
      defaultPackage.${system} = self.packages.${system}.${app};

      apps.${system}.${app} = {
        type = "app";
        program = "${self.packages.${system}.${app}}/bin/${app}";
      };
      defaultApp.${system} = self.apps.${system}.${app};

      checks.${system}.build = self.packages.${system}.${app};
    };
}
