{
  description = "Infrastructure study environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              bind.dnsutils
              cilium-cli
              curl
              docker-client
              gh
              git
              iperf3
              kubectl
              kubernetes-helm
              openssl
              qemu
              talosctl
              tcpdump
              yq-go
            ] ++ lib.optionals stdenv.hostPlatform.isLinux [
              bpftools
              hping
              iproute2
              iptables
              iputils
              mtr
              netcat-openbsd
              strace
            ];
          };
        }
      );
    };
}
