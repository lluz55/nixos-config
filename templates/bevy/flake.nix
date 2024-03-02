{
  inputs = {
    rust-overlay.url = "github:oxalica/rust-overlay";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs-unstable,
    rust-overlay,
  }: let
    overlays = [(import rust-overlay)];
    unstable = import nixpkgs-unstable {
      inherit system overlays;
    };

    system = "x86_64-linux";
    app = "game";

    rust = unstable.rust-bin.nightly.latest.default.override {extensions = ["rust-src"];};
    rustPlatform = unstable.makeRustPlatform {
      cargo = rust;
      rustc = rust;
    };

    shellInputs = with unstable; [
      rust
      clang
      mold
    ];
    appNativeBuildInputs = with unstable; [
      pkg-config
    ];
    appBuildInputs =
      appRuntimeInputs
      ++ (with unstable; [
        udev
        alsaLib
        vulkan-tools
        vulkan-headers
        vulkan-validation-layers
      ]);
    appRuntimeInputs = with unstable; [
      vulkan-loader
      xorg.libXcursor
      xorg.libXi
      xorg.libX11
      xorg.libXrandr
      libxkbcommon
      udev
    ];
  in {
    devShells.${system}.${app} = unstable.mkShell {
      nativeBuildInputs = appNativeBuildInputs;
      buildInputs = shellInputs ++ appBuildInputs;

      shellHook = ''
        export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${unstable.lib.makeLibraryPath appRuntimeInputs}"
        ln -fsT ${rust} ./.direnv/rust
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
