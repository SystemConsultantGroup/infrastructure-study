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
              nodejs
              cdrtools
              openssh
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
              traceroute
            ];
            shellHook = ''
              export LAB_QEMU_FIRMWARE="${pkgs.qemu}/share/qemu/edk2-aarch64-code.fd"
              if [ "$(uname -s)" = Darwin ]; then
                echo '현재는 Mac의 Nix shell입니다. Linux 명령 ip는 여기서 실행하지 않습니다.'
              fi
              echo '실습 폴더: cd topics/mac-ip-tcp/lab'
              echo '환경 준비(한 번): ./lab up'
              echo 'PC 접속: ./lab pc a  또는  ./lab pc b'
              echo '[PC-A ...] / [PC-B ...] 프롬프트가 나온 뒤 ip, ping 등의 실습 명령을 실행하세요.'
            '';
          };
        }
      );
    };
}
