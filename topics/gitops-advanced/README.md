# GitOps (Advanced)

[전체 커리큘럼으로 돌아가기](../../README.md)

## 기본 정보

- **대상:** 플랫폼 엔지니어
- **담당 인원:** 3명
- **시간:** 120분

## 학습 목표

[SystemConsultantGroup/kubernetes](https://github.com/SystemConsultantGroup/kubernetes)를 플랫폼의 기준 상태(source of truth)로 이해하고, reconciliation 구조와 운영 작업의 경계를 설명합니다.

모든 구성 요소와 명령을 외우기보다 변경이나 장애 상황에서 근거를 모으고 위험을 판단할 수 있는 운영 모델을 만드는 것이 목표입니다.

## 준비 방향

declarative reconciliation과 bootstrap, 변경, 복구 과정에서 필요한 imperative 작업의 관계를 중심으로 준비합니다. repository와 `k --help`를 일차 자료로 사용하되, 구조를 디렉터리 순서대로 소개하지는 않습니다.

이 주제를 준비하거나 진행하는 동안 운영 클러스터에 변경 또는 파괴 작업을 실행하지 않습니다. 시연이 필요하다면 읽기 전용, 로컬, ephemeral 환경을 사용합니다.

## 탐구 주제

### 기준 상태와 reconciliation 구조

- Git에 선언된 상태와 다른 시스템에만 존재하는 상태는 어떻게 구분되는가?
- 최상위 Application에서 플랫폼 및 애플리케이션 상태로 이어지는 구조는 어떻게 형성되는가?
- 생성된 artifacts와 수정해야 할 원본 선언을 어떻게 구분할 수 있는가?
- 여러 controller와 외부 시스템 사이의 ownership은 어디에서 나뉘는가?

모든 플랫폼 구성 요소를 다루기보다 전체 구조를 잘 보여주는 경로를 준비팀이 선택합니다.

### 변경의 안전성과 신뢰

- 병합 전에 확인할 수 있는 문제와 클러스터에서만 드러나는 문제는 무엇인가?
- 검증, 검토, admission은 각각 어떤 경계를 보호하는가?
- 추적 중인 branch의 변경이 운영 상태에 미치는 영향은 무엇인가?
- Secret은 저장, 복호화, 실제 값으로의 변환, 실행 환경 전달 과정에서 누구의 신뢰를 필요로 하는가?

실제 Secret 값보다 identifiers, 키, controller, 외부 서비스 사이의 신뢰 관계에 집중합니다.

### `k`와 imperative 작업

- `k`는 어떤 운영 지식과 복잡성을 표준화하는가?
- 어떤 작업은 관찰이나 검증이고, 어떤 작업은 시스템 상태를 바꾸는가?
- 변경, 파괴, 복구 작업의 위험을 어떤 기준으로 분류할 수 있는가?
- imperative 작업이 끝난 뒤 상태 관리 책임을 다시 declarative reconciliation에 맡기려면 무엇이 필요한가?

분류 방식과 대표 명령은 준비팀이 선택합니다. 전체 명령 목록을 만들 필요는 없습니다.

### Bootstrap과 복구 경계

- Argo CD와 플랫폼 controller가 동작하기 전에 무엇이 준비되어야 하는가?
- declarative 시스템을 시작하기 위해 불가피하게 imperative인 단계는 무엇인가?
- 클러스터를 다시 만들거나 복구하려면 Git 밖의 어떤 상태가 필요한가?
- Bootstrap이 끝났다는 것은 ownership 관점에서 무엇을 의미하는가?

### 장애 판단

준비팀은 병합 후 convergence 실패, Secret 제공 실패, 노드 교체, 부분 업그레이드, 수동 변경으로 인한 상태 불일치 등을 참고해 적절한 사례를 선택합니다.

- 기준이 되는 desired state는 무엇인가?
- 판단에 필요한 근거는 어디에서 얻는가?
- Reconciliation을 계속할지 멈출지 어떤 기준으로 결정하는가?
- 필요한 imperative 작업의 위험과 복구 완료를 어떻게 판단하는가?

목표는 완전한 운영 절차서가 아니라 다른 장애에도 적용할 수 있는 판단 과정입니다.

## 범위

### 핵심 범위

- 최상위 reconciliation과 상태 계층
- 플랫폼과 애플리케이션의 책임 경계
- 검증, 병합, Secret의 신뢰 모델
- `k` 작업의 목적과 위험 판단
- declarative 작업과 imperative 작업의 경계
- Bootstrap 또는 장애 사례

### 범위 밖

- 모든 플랫폼 구성 요소 소개
- Argo CD UI와 관리 방법
- 전체 `k` 명령어 설명
- 완전한 재해 복구 절차서
- 실제 운영 환경 변경, 파괴 작업, Secret 값
- 애플리케이션 등록 절차의 반복

## 참고 자료

- [SystemConsultantGroup/kubernetes](https://github.com/SystemConsultantGroup/kubernetes)
- repository의 최상위 Application, 플랫폼 및 애플리케이션 선언, 검증 workflow, 패치, `scripts/k` 관련 문서와 코드
- `k --help`

## 준비 결과

- 위 목표를 다루는 120분 세션
- 조사에 사용한 참고 자료

사례 수, 다이어그램, 로컬 검증, 명령 시연의 포함 여부는 준비팀이 결정합니다.
