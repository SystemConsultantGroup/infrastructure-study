# Linux Network Stack (Advanced)

[전체 커리큘럼으로 돌아가기](../../README.md)

## 기본 정보

- **대상:** 플랫폼 엔지니어
- **담당 인원:** 3명
- **시간:** 120분

## 학습 목표

Linux에서 TCP 데이터가 애플리케이션과 네트워크 장치 사이를 오가는 원리를 이해하고, 이 개념을 Cilium 기반 Kubernetes 통신에 적용합니다.

특정 다이어그램을 정답처럼 외우기보다 문서, 설정, 관찰 결과를 바탕으로 실제 환경의 경로를 추론하는 방법에 초점을 맞춥니다.

## 준비 방향

하나의 TCP 연결을 기준으로 송수신 흐름을 살펴보는 것을 권장하지만, 구체적인 애플리케이션과 Kubernetes 통신 유형은 준비팀이 선택합니다. 모든 커널 세부 사항을 다루기보다 선택한 경로를 설명하는 데 필요한 깊이를 판단합니다.

아래 질문은 탐구의 출발점이며, 준비팀은 관심과 시간에 맞게 묶거나 덜어낼 수 있습니다.

## 탐구 주제

### 애플리케이션과 커널의 경계

- `write()`와 `read()`의 성공은 각각 무엇을 의미하는가?
- 애플리케이션의 바이트 스트림은 커널 안에서 어떤 형태로 다뤄지는가?
- 소켓 버퍼와 TCP 상태는 전송 과정에서 어떤 역할을 하는가?
- 데이터가 지연되거나 유실될 수 있는 지점은 어디인가?

### Linux 송수신 경로

- 시스템 호출, TCP/IP 처리, 라우팅, 큐 처리, 네트워크 장치는 어떤 책임을 나누는가?
- 송신 경로와 수신 경로는 어디에서 대칭적이고 어디에서 다른가?
- 인터럽트, polling, NAPI, offloading은 throughput과 latency에 어떤 영향을 줄 수 있는가?
- 깊이 이해해야 할 구현과 추상화해도 되는 구현을 어떻게 구분할 것인가?

### namespace, eBPF, Cilium

- 네트워크 namespace와 가상 네트워크 장치가 추가되면 경로와 상태의 ownership은 어떻게 달라지는가?
- Cilium은 Linux 네트워크 경로의 어느 지점에 개입할 수 있는가?
- 서비스 선택, 정책 적용, 연결 상태는 어떤 방식으로 표현될 수 있는가?
- 배포 설정에 따라 달라지는 경로를 확인하려면 어떤 근거가 필요한가?

### Kubernetes 경로 도출

준비팀이 선택한 Cilium 기반 TCP 연결 하나에 일반 Linux 모델을 적용합니다.

- 어떤 부분은 일반 Linux 경로이고, 어떤 부분은 Kubernetes 또는 Cilium이 더하는가?
- namespace, 장치, 라우팅, 정책의 경계는 어디에 있는가?
- 확인한 사실, 관찰한 결과, 추론한 내용을 어떻게 구분할 것인가?

동일 노드, 노드 간, 외부 통신 가운데 무엇을 선택할지는 자유지만, 여러 경로를 얕게 나열하기보다 한 경로를 일관되게 설명하는 편이 좋습니다.

### 관찰 방법

`ss`, `tcpdump`, `bpftool`, Cilium 관찰 기능, 커널 추적 기능 등에서 필요한 도구를 선택할 수 있습니다. 각 도구가 보여주는 계층과 보여주지 못하는 영역을 함께 설명합니다.

## 범위

### 핵심 범위

- 시스템 호출과 소켓 버퍼
- TCP 송수신 과정
- 라우팅, 큐 처리, 네트워크 장치
- 네트워크 namespace와 가상 네트워크 장치
- eBPF와 Cilium의 개입 지점
- Cilium 기반 Kubernetes 연결 사례 하나

### 범위 밖

- 가능한 모든 Kubernetes 통신 경로 비교
- 모든 Cilium 배포 방식과 설정 항목 소개
- Gateway 또는 Envoy 경로의 전수 분석
- 커널 네트워킹 구현 전체
- congestion control 알고리즘의 세부 비교

## 참고 자료

- [Linux kernel networking 문서](https://docs.kernel.org/networking/)
- [Linux kernel NAPI 문서](https://docs.kernel.org/networking/napi.html)
- [Linux kernel scaling 문서](https://docs.kernel.org/networking/scaling.html)
- [Cilium eBPF datapath 문서](https://docs.cilium.io/en/stable/network/ebpf/)
- [Cilium: Life of a Packet](https://docs.cilium.io/en/latest/network/ebpf/lifeofapacket/)
- [BPF 문서](https://docs.kernel.org/bpf/)

2차 자료의 다이어그램은 가설로 활용하고, 가능한 경우 최신 1차 자료와 실제 환경을 통해 검토합니다.

## 준비 결과

- 위 목표를 다루는 120분 세션
- 조사에 사용한 참고 자료

다이어그램, 추적 자료, 실습의 구성은 준비팀이 결정합니다.
