{
  description = "my nixops & ansible configruation";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          devShell = pkgs.mkShell {
            shellHook = ''
              nvim --headless -c "checkhealth" -c "qall"
            '';
            buildInputs = with pkgs;
              [
                nodejs
                cmake
                gcc
                python39
              ];
          };
        }
      );
}
