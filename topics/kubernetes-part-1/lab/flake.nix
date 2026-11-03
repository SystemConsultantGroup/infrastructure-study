{
  description = "Kubernetes Part 1 lab tools";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    in
    {
      devShells = nixpkgs.lib.genAttrs systems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShellNoCC {
            packages = [
              pkgs.curl
              pkgs.kubectl
              pkgs.python3
            ] ++ (if pkgs.stdenv.hostPlatform.isLinux then [
              pkgs.docker
              pkgs.k3d
            ] else [
              pkgs.docker-client
              (pkgs.colima.override { docker = pkgs.docker-client; })
            ]);
            shellHook = ''
              export KUBECONFIG="$PWD/.kubeconfig.local"
              unset DOCKER_CONTEXT DOCKER_SOCK
            '' + (if pkgs.stdenv.hostPlatform.isLinux then ''
              # WSL/Linux uses its host Docker Engine, without a nested VM.
              export DOCKER_HOST="unix:///var/run/docker.sock"
            '' else ''
              # Preserve an existing profile, including Colima's XDG location.
              # Older lab shells set ~/.colima even when that directory did not
              # exist; Colima 0.10.3 then silently fell back to ~/.config/colima.
              if [ -z "''${COLIMA_HOME:-}" ] || { [ "$COLIMA_HOME" = "$HOME/.colima" ] && [ ! -d "$COLIMA_HOME" ]; }; then
                if [ -d "$HOME/.colima" ]; then
                  export COLIMA_HOME="$HOME/.colima"
                else
                  export COLIMA_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}/colima"
                fi
              fi
              # This Colima version only honors COLIMA_HOME if it exists.
              mkdir -p "$COLIMA_HOME"
              export COLIMA_HOME
              export DOCKER_HOST="unix://$COLIMA_HOME/infra-study/docker.sock"
            '');
          };
        }
      );
    };
}
