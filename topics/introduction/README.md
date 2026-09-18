# Introduction + Docker

[전체 커리큘럼으로 돌아가기](../../README.md)

## 기본 정보

* **대상:** 전체
* **담당 인원:** 2명
* **시간:** 120분

## 학습 목표

환경을 선언적으로 구성하는 관점을 이해하고, Nix를 이용해 development shell과 container image를 만드는 흐름을 경험합니다.

참가자는 새로운 환경에서도 repository의 development shell을 사용할 수 있어야 하며, 같은 Nix 정의를 바탕으로 container image를 빌드하고 실행할 수 있어야 합니다. 또한 이 방식이 재현성, 구성 공유, build 재사용 측면에서 어떤 장점과 한계를 가지는지 설명할 수 있어야 합니다.

## 준비 방향

설치 절차나 Dockerfile 작성법보다 **환경과 build 결과를 코드로 정의하는 이유**에 초점을 맞춥니다.

**Declarative 방식 → Nix → development shell → container의 개념 → Nix 기반 image build → 장단점 검토**의 흐름으로 연결하는 것을 권장합니다.

아래 질문은 조사의 출발점입니다. 모든 질문을 같은 깊이로 다룰 필요는 없습니다.

## 탐구 주제

### Imperative와 Declarative

* 명령을 순서대로 실행해 환경을 만드는 방식은 어떤 상태에 의존하는가?
* 원하는 상태를 선언하는 방식은 무엇을 다르게 만드는가?
* 재현 가능하다는 것은 무엇을 보장하며, 무엇까지 보장하지 않는가?
* 이런 관점은 이후 Kubernetes, Talos, GitOps와 어떻게 이어지는가?

### Nix와 Development Shell

* 이 스터디가 공통 환경을 구성하는 데 Nix를 사용하는 이유는 무엇인가?
* Determinate Nix와 Flake는 각각 어떤 역할을 하는가?
* `flake.lock`은 build 입력을 고정하는 데 어떤 역할을 하는가?
* development shell과 host environment의 경계는 어디인가?
* Nix의 dependency graph와 cache는 반복되는 build에서 무엇을 재사용할 수 있게 하는가?

### Container의 개념

* container는 어떤 문제를 해결하기 위해 사용하는가?
* container image와 실행 중인 container는 무엇이 다른가?
* container runtime은 어떤 역할을 하는가?
* image에 포함되는 상태와 host에 남아 있는 상태는 무엇인가?
* 같은 image를 실행해도 달라질 수 있는 조건에는 무엇이 있는가?

Dockerfile을 image의 출발점으로 삼지 않고, **실행 환경을 전달 가능한 image로 만든다**는 관점에서 접근합니다.

### Nix로 Container Image 만들기

앞서 사용한 Nix 정의를 바탕으로 Docker에서 실행할 수 있는 image를 만듭니다.

* development shell과 container image는 어떤 package 정의를 공유할 수 있는가?
* 개발에 필요한 도구와 application 실행에 필요한 dependency는 어떻게 다른가?
* Nix가 만든 filesystem과 metadata는 어떻게 container image가 되는가?
* image를 build하는 것과 container runtime에서 실행하는 것은 어떻게 구분되는가?
* image build에 Docker daemon이 반드시 필요한가?

준비팀은 development shell에서 application을 실행하고, 같은 Nix 정의를 이용해 image를 빌드한 뒤 container로 실행하는 흐름을 보여줍니다.

### 다시 Declarative 환경으로

* development와 image build가 같은 정의를 공유하면 어떤 중복과 차이를 줄일 수 있는가?
* dependency가 바뀌었을 때 어떤 부분만 다시 build하면 되는가?
* Nix의 build graph와 cache는 build 속도와 재현성에 어떤 영향을 주는가?
* host의 기존 상태에 덜 의존하는 build는 어떤 장점을 가지는가?
* Nix로 environment와 image를 함께 관리하는 대신 감수해야 하는 복잡성은 무엇인가?

## 범위

### 핵심 범위

* imperative 방식과 declarative 방식의 차이
* Determinate Nix와 Flake
* 공통 development shell 사용
* container image, container, container runtime
* Nix를 사용한 container image build
* development와 runtime 사이의 configuration 공유
* 재현성, dependency 재사용, build cache의 장단점

### 범위 밖

* Dockerfile 작성법
* Nix 언어와 derivation 내부 구조
* Flake 작성법
* container runtime 내부 구조
* OCI specification 상세
* container registry 운영
* 일반적인 Linux 또는 Docker 관리

## 참고 자료

* [Determinate Nix 문서](https://docs.determinate.systems/)
* [NixOS Wiki: Flakes](https://wiki.nixos.org/wiki/Flakes)
* [Nixpkgs Manual: dockerTools](https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-dockerTools)
* 이 repository의 `flake.nix`와 `flake.lock`

## 준비 결과

* 위 목표를 다루는 120분 세션
* 조사에 사용한 참고 자료

설명에 사용할 사례와 image build 시연의 구성은 준비팀이 결정합니다.
