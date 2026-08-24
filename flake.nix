{
  description = "Snake in Odin";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      lib = nixpkgs.lib;
      appName = "snake-odin";
      systems = [
        "aarch64-darwin"
      ];
      forAllSystems = f: lib.genAttrs systems (system: f system);
      perSystem =
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          isLinux = pkgs.stdenv.isLinux;
          package = pkgs.stdenv.mkDerivation {
            pname = appName;
            version = "0.2.0";
            src = lib.sources.cleanSource ./.;

            nativeBuildInputs = [ pkgs.odin ];
            buildInputs = [ pkgs.raylib ];

            buildPhase = ''
              runHook preBuild
              odin build ./ -out:${appName}
              runHook postBuild
            '';
            installPhase = ''
              runHook preInstall
              install -Dm755 ${appName} -t $out/bin
              runHook postInstall
            '';
          };
        in
        {
          inherit
            pkgs
            isLinux
            package
            ;
        };
    in
    {
      packages = forAllSystems (
        system:
        let
          s = perSystem system;
        in
        {
          ${appName} = s.package;
          default = s.package;
        }
      );

      apps = forAllSystems (
        system:
        let
          s = perSystem system;
        in
        {
          ${appName} = {
            type = "app";
            program = "${s.package}/bin/${appName}";
          };
          default = {
            type = "app";
            program = "${s.package}/bin/${appName}";
          };
        }
      );
      devShells = forAllSystems (
        system:
        let
          s = perSystem system;
        in
        {
          default = s.pkgs.mkShell {
            packages = with s.pkgs; [
              nixfmt
              nixd
              odin
              raylib
            ];
          };
        }
      );
    };
}
