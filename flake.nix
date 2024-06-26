{
  description = "Husjon Validator - gomod2nix flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.gomod2nix.url = "github:nix-community/gomod2nix";
  inputs.gomod2nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.gomod2nix.inputs.flake-utils.follows = "flake-utils";
  inputs.nix2container.url = "github:nlewo/nix2container";

  outputs = { self, nixpkgs, flake-utils, gomod2nix, nix2container }:
    (flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ gomod2nix.overlays.default ];
          };

          # The current default sdk for macOS fails to compile go projects, so we use a newer one for now.
          # This has no effect on other platforms.
          callPackage = pkgs.darwin.apple_sdk_11_0.callPackage or pkgs.callPackage;
          # nix2containerPkgs = nix2container.${system};
        in
        rec {
          hjsonapp = callPackage ./. {
            inherit (gomod2nix.legacyPackages.${system}) buildGoApplication;
          };
          packages.dockerContainer = nix2container.packages.${system}.nix2container.buildImage
            {
              #pkgs.dockerTools.buildLayeredImage {
              name = "hujson";
              tag = "latest";
              # created = "now";
              copyToRoot = pkgs.buildEnv {
                name = "img-root";
                paths = [ hjsonapp ];
                pathsToLink = [ "/bin" ];
              };
              config = {
                Cmd = [ "${hjsonapp}/bin/hujson-validator" ];
                ExposedPorts = {
                  "8080/tcp" = { };
                };
              };
            };
          packages.default = hjsonapp;
          devShells.default = callPackage
            ./shell.nix
            {
              inherit (gomod2nix.legacyPackages.${system}) mkGoEnv gomod2nix;
            };
        })
    );
}
