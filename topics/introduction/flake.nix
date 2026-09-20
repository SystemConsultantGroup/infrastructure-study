{
  description = "SCG week 1: one Java definition, development shell and Linux image";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      perSystem = system:
        let
          pkgs = import nixpkgs { inherit system; };
          java = pkgs.jdk21_headless;
          classes = pkgs.runCommand "study-api-classes" { nativeBuildInputs = [ java ]; } ''
            mkdir -p "$out"
            javac --release 21 -d "$out" ${./StudyApi.java}
          '';
        in {
          inherit pkgs java classes;
        };
    in {
      devShells = forAllSystems (system:
        let p = perSystem system;
        in { default = p.pkgs.mkShellNoCC { packages = [ p.java p.pkgs.curl ]; }; }
      );
      packages = forAllSystems (system:
        let p = perSystem system;
        in { default = p.classes; } // p.pkgs.lib.optionalAttrs p.pkgs.stdenv.hostPlatform.isLinux {
          image = p.pkgs.dockerTools.buildLayeredImage {
            name = "scg-study-api";
            tag = "week1";
            config = {
              Cmd = [ "${p.java}/bin/java" "-cp" "${p.classes}" "StudyApi" ];
              Env = [ "BIND_ADDRESS=0.0.0.0" "PORT=8080" "APP_ENV=image-default" "APP_MESSAGE=hello from the image" ];
              ExposedPorts."8080/tcp" = { };
              User = "10001:10001";
              WorkingDir = "/";
            };
          };
        }
      );
    };
}
