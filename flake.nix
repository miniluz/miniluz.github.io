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
      fetchPaperMod =
        pkgs:
        pkgs.fetchFromGitHub {
          owner = "adityatelange";
          repo = "hugo-PaperMod";
          rev = "10d3dcc0e05cee0aaca58a1305a9d824b2cf9a2a";
          hash = "sha256-OcMhe2QFPM+3iIRbGSqkUMYNjgx0N1NMCFdG55rruu0=";
        };

    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          paper-mod = fetchPaperMod pkgs;
        in
        {
          default =
            pkgs.runCommandLocal "miniluz-blog"
              {
                nativeBuildInputs = with pkgs; [
                  hugo
                  just
                ];
                src = ./.;
              }
              ''
                cp -r $src/* .
                mkdir -p themes
                ln -snf ${paper-mod} themes/PaperMod
                just build
                cp -r public $out
              '';
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          paper-mod = fetchPaperMod pkgs;
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
