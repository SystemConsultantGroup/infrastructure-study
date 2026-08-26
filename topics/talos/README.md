# Talos (Advanced)

[전체 커리큘럼으로 돌아가기](../../README.md)

## 기본 정보

- **대상:** 플랫폼 엔지니어
- **담당 인원:** 2명
- **시간:** 120분

## 학습 목표

Talos로 관리되는 Kubernetes node의 설계 철학과 lifecycle을 이해하고, 일회용 QEMU node를 `talosctl`로 관찰해 이론과 실제 동작을 연결합니다.

이론을 중심으로 하되 범위가 분명한 실습을 포함합니다. 운영 runbook을 작성하는 세션은 아닙니다.

## 준비 방향

Talos가 해결하려는 문제에서 출발해 운영 모델을 도출합니다. 하나의 node가 configuration을 받아 시작되고, 관찰되고, reboot되거나 종료되는 과정을 개념적으로 따라갑니다.

QEMU 실습은 mental model을 눈으로 확인하기 위한 수단입니다. 전체 Kubernetes 클러스터 bootstrap, upgrade, recovery 실습으로 넓히지 않습니다. 이 저장소의 `k` interface는 GitOps (Advanced)에서 다룹니다.

## 탐구 방향

### 1. 문제와 설계 제약 찾기

다음 질문을 조사합니다.

- Talos는 node drift와 운영 불확실성 가운데 어떤 문제를 해결하려 하는가?
- Kubernetes node의 역할에 대해 어떤 전제를 두고 있는가?
- 일반적인 서버 관리 방식과 access model은 어떻게 다른가?
- 어떤 관리 기능을 의도적으로 없애거나 제한했는가?
- 그 선택이 security와 operability에 미치는 영향은 무엇인가?

기능을 나열하는 데 그치지 말고, 설계가 만드는 trade-off를 함께 설명합니다.

### 2. Machine state model 만들기

다음 내용을 탐구합니다.

- 원하는 machine state는 어떻게 표현되는가?
- 어떤 configuration이 machine별, cluster 공통, 또는 파생된 값인가?
- Node는 configuration을 어떻게 받고 검증하는가?
- 실행 중 적용할 수 있는 변경과 lifecycle 전환이 필요한 변경은 무엇인가?
- Machine API 접근을 위한 secret과 trust는 어떻게 형성되는가?
- Operator는 선언한 configuration과 실제 관찰된 상태를 어떻게 구분해야 하는가?

개념 모델을 먼저 세운 뒤 대표 구성 하나를 예시로 사용합니다.

### 3. Node lifecycle 따라가기

다음 단계를 포함하는 high-level lifecycle을 구성합니다.

- 최초 boot
- Configuration 확보
- Service 시작
- Kubernetes cluster 참여
- 정상 상태 관찰
- 구성 변경
- Reboot 또는 shutdown
- Maintenance 및 recovery state

각 단계에서 어떤 증거를 관찰할 수 있는지, Kubernetes 자체가 동작하지 않을 때도 사용할 수 있는 control interface는 무엇인지 질문합니다.

세부 etcd 내부 구조와 production recovery 절차는 범위에서 제외합니다.

### 4. QEMU 실습 준비하기

최신 Talos 공식 QEMU 가이드를 이용해 일회용 환경을 만듭니다. 이론을 확인하는 데 필요한 범위만 실습합니다.

1. QEMU에서 Talos node 또는 최소 local environment를 시작합니다.
2. `talosctl` access를 설정합니다.
3. Machine state와 service를 확인합니다.
4. Log와 effective configuration을 살펴봅니다.
5. 관찰한 상태를 앞에서 만든 lifecycle과 연결합니다.
6. Node를 reboot하거나 종료한 뒤 상태 전환을 관찰합니다.
7. 실습 환경을 정리합니다.

준비 과정에서 다음을 확인합니다.

- 호스트 architecture와 acceleration 요구 사항
- 필요한 권한 및 networking 지원
- Linux와 macOS QEMU host 사이의 차이
- 세션 중 virtualization을 사용할 수 없을 때의 대체 시연 방법

Production credential이나 configuration은 사용하지 않습니다.

### 5. 운영 모델 평가하기

마지막으로 다음을 논의합니다.

- 어떤 종류의 운영 실수를 방지하기 쉬워지는가?
- 익숙한 debugging 방식 가운데 사용할 수 없게 되는 것은 무엇인가?
- 그 자리를 어떤 evidence와 workflow가 대신하는가?
- 어떤 장애는 repair, reconfiguration, replacement 가운데 무엇이 필요한가?
- 이 모델은 declarative infrastructure 철학에 어떤 장점과 제약을 주는가?

## 범위

### 반드시 다룰 내용

- Talos의 설계 목표와 trade-off
- Desired state로서 머신 구성
- 노드 boot와 lifecycle 개념
- API access와 관찰 방식
- 개념적인 maintenance 및 recovery state
- 일회용 `talosctl`/QEMU 관찰 실습

### 다루지 않을 내용

- 이 저장소의 `k` 명령
- SCG 저장소 전체 구조
- 완전한 Kubernetes 클러스터 실습
- 세부 etcd 내부 구조
- Talos 또는 Kubernetes upgrade 절차
- 파괴적인 recovery 실습
- Production hardware별 절차

## 시작 자료

- [Talos Linux 문서](https://docs.siderolabs.com/talos/)
- [Talos QEMU 플랫폼 guide](https://docs.siderolabs.com/talos/v1.13/platform-specific-installations/local-platforms/qemu)
- [Talos support matrix](https://docs.siderolabs.com/talos/v1.13/getting-started/support-matrix)
- [SystemConsultantGroup/kubernetes](https://github.com/SystemConsultantGroup/kubernetes)의 대표적인 `state.yaml`과 `patches/`: 일반적인 모델을 세운 뒤 사례로만 사용합니다.

링크된 version이 계속 최신이라고 가정하지 말고, 실습에서 선택한 Talos version에 맞는 문서를 사용합니다.

## 최소 준비 사항

- Talos의 설계와 노드 lifecycle을 중심으로 세션을 진행합니다.
- 일회용 QEMU 관찰 실습을 미리 준비하고 검증합니다.
- 조사에 사용한 참고 자료를 공유합니다.
