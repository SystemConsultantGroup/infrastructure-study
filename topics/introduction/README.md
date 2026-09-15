# Introduction

[전체 커리큘럼으로 돌아가기](../../README.md)

## 기본 정보

- **대상:** 전체
- **담당 인원:** 2명
- **시간:** 120분

## 학습 목표

이후 차시에서 함께 사용할 Linux/Nix 환경을 준비하고, 재현 가능한 개발 환경이 왜 필요한지 이해합니다.

참가자는 새로운 환경에서도 repository가 제공하는 development shell을 사용할 수 있어야 합니다. 또한 repository가 보장하는 상태와 호스트에 남아 있는 차이를 구분할 수 있어야 합니다.

## 준비 방향

설치 절차 자체보다 **환경을 코드로 정의하는 이유**에 초점을 맞춥니다. 준비팀은 설명, 시연, 비교 실험 등 주제에 적합한 형식을 자유롭게 선택할 수 있습니다.

아래 질문은 조사의 출발점입니다. 모든 질문을 같은 깊이로 다룰 필요는 없습니다.

## 탐구 주제

### 공통 환경의 기준

- 이후 차시를 진행하려면 어떤 operating system, 권한, 네트워크 접근이 필요한가?
- Linux를 직접 사용하는 경우와 가상 환경을 사용하는 경우에는 어떤 차이가 있는가?
- 참가자가 미리 알아야 할 shell과 파일 시스템 개념은 어느 정도인가?

### Imperative 환경과 Declarative 환경

- 도구를 하나씩 수동 설치하는 방식은 무엇에 의존하는가?
- imperative 방식의 절차 가운데 무엇을 declarative 상태로 옮길 수 있는가?
- 재현 가능하다는 말은 무엇을 보장하며, 무엇까지 보장하지는 않는가?
- 이런 구분은 이후 Kubernetes, Talos, GitOps와 어떻게 이어지는가?

### Nix와 Flake

- 이 스터디가 공통 도구 환경에 Nix를 선택한 이유는 무엇인가?
- Determinate Nix와 Flake는 각각 어떤 문제를 해결하는가?
- `flake.lock`은 재현 가능성에 어떤 역할을 하는가?
- development shell에 들어가고 나올 때 호스트에는 무엇이 남는가?

### 실제 사용과 문제 해결

준비팀은 초기 환경에서 repository의 development shell까지 도달하는 흐름을 보여줍니다. 구체적인 시연 방식과 확인할 도구는 자유롭게 정합니다.

환경 구성이 실패하는 사례를 다룬다면 명령을 나열하기보다, 전제와 상태를 어떻게 확인할지에 집중합니다.

## 범위

### 핵심 범위

- 스터디에 필요한 Linux 환경
- imperative 방식과 declarative 방식의 차이
- Determinate Nix 설치와 Flake 사용
- 공통 development shell 사용
- 재현 가능성의 범위와 한계

### 범위 밖

- Nix 언어와 derivation 내부 구조
- Flake 작성법
- 일반적인 Linux 시스템 관리 전반
- 광범위한 command-line 입문

## 참고 자료

- [Determinate Nix 문서](https://docs.determinate.systems/)
- [NixOS Wiki: Flakes](https://wiki.nixos.org/wiki/Flakes)
- 이 repository의 `flake.nix`와 `flake.lock`

## 준비 결과

- 위 목표를 다루는 120분 세션
- 조사에 사용한 참고 자료

발표 구성, 다이어그램, 설치 문서, 실습의 포함 여부는 준비팀이 결정합니다.
