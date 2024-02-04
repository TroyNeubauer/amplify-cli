{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        nodejs = pkgs.nodejs-18_x;
        yarn = pkgs.yarn-4_x;
        amplify-cli = pkgs.callPackage ./package.nix {
          inherit yarn;
          src = self;
        };
        # aws_amplify = pkgs.stdenv.mkDerivation {
        #   name = "aws-amplify";
        #   src = ./.;
        #   buildInputs = [pkgs.yarn node-modules];
        #   buildPhase = ''
        #     ln -s ${node-modules}/libexec/yarn-nix-example/node_modules node_modules
        #     ${pkgs.yarn}/bin/yarn build
        #   '';
        #   installPhase =  ''
        #   mkdir $out
        #   mv dist $out/lib
        #   '';

        # };
      in 
        {
          packages = {
            # node-modules = offlineCache;
            default = amplify-cli;
          };
        }
    );
}
