# Linux Network Stack (Advanced)

[전체 커리큘럼으로 돌아가기](../../README.md)

## 기본 정보

- **대상:** 플랫폼 엔지니어
- **담당 인원:** 3명
- **시간:** 120분

## 학습 목표

Linux kernel 안에서 TCP write와 read가 처리되는 lifecycle을 추적하고, 그 기반 위에서 Cilium을 사용하는 Kubernetes의 대표적인 통신 경로 하나를 조사합니다.

어디에나 그대로 적용되는 packet-path 다이어그램을 암기하는 것이 목표가 아닙니다. Linux의 동작 원리, 실제 배포 설정, 공식 문서, 관찰 결과를 조합해 주어진 환경의 경로를 스스로 도출하는 방법을 익혀야 합니다.

## 준비 방향

한 프로세스가 쓴 byte가 다른 프로세스의 `read()`에 도달하는 과정을 세션 전체의 줄기로 삼습니다. Network namespace, Kubernetes, Cilium을 도입하기 전에 일반적인 Linux 경로부터 충분히 이해합니다.

이 차시는 kernel 동작을 깊게 다룹니다. 가능한 Kubernetes 통신 경로를 넓게 나열하기보다, 하나의 일관된 경로를 깊게 추적합니다.

## 탐구 방향

### 1. 추적의 시작점과 끝점 정의하기

구체적인 TCP 클라이언트와 서버를 정하고 다음을 확인합니다.

- 어느 userspace call에서 추적을 시작하고 끝낼 것인가?
- `write()`가 성공했다는 것은 정확히 무엇을 의미하는가?
- `read()`가 성공했다는 것은 무엇을 의미하는가?
- 어떤 상태가 userspace에 있고, 어떤 상태가 kernel space에 있는가?
- 데이터는 어느 지점에서 복사되고, queue에 쌓이고, segment로 나뉘고, 지연되거나 유실될 수 있는가?

애플리케이션이 다루는 byte stream, TCP segment, IP packet, link-layer frame의 경계를 분명히 합니다.

### 2. 송신 경로 따라가기

송신 프로세스에서 network device까지의 경로를 조사하고 다음 요소의 책임을 찾습니다.

- Syscall과 소켓 계층
- 소켓 send 버퍼
- TCP state와 segmentation
- IP routing과 출력 처리
- 커널 내부 패킷 표현
- Queueing discipline
- 디바이스 및 driver 큐
- Offload 기능
- Physical 또는 virtual 디바이스 경계

정확한 mental model을 유지하기 위해 반드시 필요한 세부 사항과 추상화해도 되는 부분을 준비팀이 판단합니다.

### 3. 수신 경로 따라가기

네트워크에서 들어온 데이터가 수신 프로세스에 도달하는 방향으로 살펴봅니다.

- Kernel은 처리할 일이 생겼음을 어떻게 아는가?
- Interrupt, polling, receive queue는 어디에서 등장하는가?
- 해당 protocol과 socket은 어떻게 선택되는가?
- 순서 정리와 acknowledgement는 어디에서 처리되는가?
- Block된 프로세스는 어떻게 다시 실행 가능한 상태가 되는가?
- Byte는 언제 `read()`가 읽을 수 있는 상태가 되는가?

송신과 수신을 별개의 그림으로 끝내지 말고, 하나의 lifecycle로 연결합니다.

### 4. Namespace와 virtual device 도입하기

일반적인 경로를 세운 다음 다음을 조사합니다.

- 프로세스가 network namespace 안에서 실행되면 무엇이 달라지는가?
- 어떤 network state가 namespace에 속하는가?
- Virtual device는 namespace와 host path를 어떻게 연결하는가?
- TCP 처리 가운데 그대로 유지되는 부분은 무엇인가?
- 어떤 라우팅 또는 forwarding 결정이 새로 추가되는가?

모델을 검증하는 데 도움이 된다면 작은 namespace 실습을 준비할 수 있습니다. 다만 환경 구성 자체가 세션을 차지하지 않도록 합니다.

### 5. Cilium이 개입하는 방식 조사하기

Linux와 Cilium의 1차 자료를 이용해 다음을 알아봅니다.

- Cilium은 어떤 Linux attachment point에서 connection에 개입할 수 있는가?
- eBPF map에는 어떤 상태가 저장될 수 있는가?
- Service 선택과 policy enforcement는 어떻게 표현될 수 있는가?
- 기존 Linux networking mechanism 가운데 여전히 참여하는 것은 무엇인가?
- Cluster configuration에 따라 달라지는 부분은 무엇이며, 이를 어떻게 확인할 수 있는가?

일반적인 Cilium 다이어그램을 그대로 정답으로 삼지 않습니다. 특정 cluster의 실제 경로를 판단하려면 무엇을 확인하거나 관찰해야 하는지 명확히 제시합니다.

### 6. Kubernetes 통신 경로 하나 도출하기

Cilium 기반 Kubernetes에서 대표적인 TCP connection 하나를 선택하고 lifecycle을 도출합니다.

- 송신 프로세스와 수신 프로세스를 식별합니다.
- Namespace와 device 전환 지점을 나열합니다.
- Routing, Service 선택, policy 결정 지점을 찾습니다.
- 일반적인 Linux path를 그대로 따르는 부분을 구분합니다.
- Kubernetes datapath가 추가하거나 바꾸는 부분을 구분합니다.
- 확인된 사실, 직접 관찰한 결과, 추론한 내용을 분리합니다.

핵심 세션에서 same-node, cross-node, external Gateway 경로를 모두 다루려 하지 않습니다.

### 7. 관찰 가능한 모델 만들기

특정 단계를 검증하는 데 도움이 되는 도구만 선택합니다. 예시는 다음과 같습니다.

- `ss`
- `tcpdump`
- `bpftool`
- Cilium observability 명령
- 커널 tracing 기능

각 관찰 결과가 어느 계층을 보여주며, 여전히 보이지 않는 부분은 무엇인지 함께 설명합니다.

## 범위

### 반드시 다룰 내용

- Syscall과 소켓 버퍼
- TCP 송수신 lifecycle
- 커널 내부 패킷 표현
- Routing과 queueing
- NAPI, 디바이스 큐, 관련 offload 개념
- Network namespace와 virtual device
- eBPF attachment point
- 직접 도출한 Cilium 기반 Kubernetes connection 하나

### 다루지 않을 내용

- 모든 Cilium 배포 mode 비교
- Same-node와 cross-node 경로의 전수 비교
- Gateway 및 Envoy traffic path
- 세부 congestion-control 알고리즘 비교
- Netfilter의 역사
- 일반적인 Cilium 설정 항목 설명

## 시작 자료

- [Linux kernel networking 문서](https://docs.kernel.org/networking/)
- [Linux kernel NAPI 문서](https://docs.kernel.org/networking/napi.html)
- [Linux kernel scaling 문서](https://docs.kernel.org/networking/scaling.html)
- [Cilium eBPF datapath 문서](https://docs.cilium.io/en/stable/network/ebpf/)
- [Cilium: Life of a Packet](https://docs.cilium.io/en/latest/network/ebpf/lifeofapacket/)
- [BPF 문서](https://docs.kernel.org/bpf/)

2차 자료의 다이어그램은 가설로 취급하고, 최신 1차 자료를 통해 검증합니다.

## 최소 준비 사항

- Kernel lifecycle과 Kubernetes 경로 연결을 중심으로 세션을 진행합니다.
- 조사에 사용한 참고 자료를 공유합니다.

이 주제는 다이어그램이나 trace가 특히 유용하지만, 실제로 어떤 자료를 만들지는 준비팀이 결정합니다.
