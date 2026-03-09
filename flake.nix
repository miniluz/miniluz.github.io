{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    __flake-compat = {
      url = "https://git.lix.systems/lix-project/flake-compat/archive/main.tar.gz";
      flake = false;
    };
  };
  outputs =
    {
      nixpkgs,
      ...
    }:
    let
      inherit (nixpkgs) lib;

      supportedSystems = [
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forAllSystems = lib.genAttrs supportedSystems;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          paper-mod = pkgs.fetchFromGitHub {
            owner = "adityatelange";
            repo = "hugo-PaperMod";
            rev = "a2eb47bb4b805116dcd34c1605d39835121f8dbe";
            hash = "sha256-JH2pPmY4dd9aPl0FDTSXG7zznoCOezEk3kmIlcS/UwI=";
          };

        in
        {
          default = pkgs.mkShellNoCC {
            allowSubstitutes = false;

            nativeBuildInputs = with pkgs; [
              hugo
              prettier
              just
              cspell
            ];
            buildInputs = [
            ];
            shellHook = ''
              mkdir -p themes
              ln -snf "${paper-mod}" themes/PaperMod
            '';

          };
        }
      );
    };
}
