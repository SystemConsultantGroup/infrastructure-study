# Kubernetes (Part 1)

[전체 커리큘럼으로 돌아가기](../../README.md)

## 기본 정보

- **대상:** 애플리케이션 개발자
- **담당 인원:** 3명
- **시간:** 120분

## 학습 목표

Kubernetes를 선언적 API와 이를 지속적으로 reconcile하는 controller의 집합으로 이해합니다. 이어서 resource identity와 ownership을 바탕으로, 서로 독립적으로 동작하는 controller들이 하나의 workload를 어떻게 구성하는지 설명합니다.

세션이 끝났을 때 참가자는 하나의 애플리케이션 선언에서 출발해, 이를 유지하기 위해 생성되는 resource의 identity와 소유 관계를 스스로 도출할 수 있어야 합니다.

## 준비 방향

리소스 종류를 나열하기 전에 Kubernetes의 철학과 control system부터 설명합니다. 하나의 간단한 container application을 세션 전체에서 일관되게 사용합니다.

Resource definition은 이 차시의 핵심입니다. Type, name, UID, namespace, label, selector, owner reference가 identity와 관계를 어떻게 만드는지 탐구합니다. 단순히 YAML 작성법을 배우는 세션이 되지 않도록 합니다.

## 탐구 방향

### 1. Kubernetes의 철학 이해하기

다음 질문을 조사합니다.

- Kubernetes는 어떤 운영 문제를 해결하기 위해 설계되었는가?
- 명령으로 동작을 지시하는 것과 desired state를 선언하는 것은 어떻게 다른가?
- API server와 controller는 이 모델에서 어떤 역할을 하는가?
- Desired state와 observed state는 어떻게 표현되는가?
- 정상 상황과 장애 상황에서 eventual convergence는 무엇을 의미하는가?
- Controller가 독립적으로 reconcile하고 반복해서 retry하도록 설계된 이유는 무엇인가?
- 이 모델에서도 애플리케이션 개발자가 책임져야 할 것은 무엇인가?

Introduction에서 살펴본 imperative/declarative 구분과 연결합니다.

### 2. 배포 아티팩트 이해하기

최소한의 container 이미지 하나를 만들고 다음을 조사합니다.

- Kubernetes에 전달하는 것은 정확히 무엇인가?
- 런타임 동작 가운데 이미지 안에 들어가는 것과 platform에 선언하는 것은 각각 무엇인가?
- 환경이 달라져도 동일하게 유지되어야 하는 속성은 무엇인가?
- Platform이 애플리케이션을 올바르게 관리하려면 애플리케이션은 어떤 신호와 interface를 제공해야 하는가?

Dockerfile 최적화와 container 런타임 내부 구현은 핵심 범위에서 제외합니다.

### 3. Kubernetes Resource definition 읽기

대표 resource를 이용해 다음을 살펴봅니다.

- `apiVersion`, `kind`, `metadata`, `spec`, `status`
- API group, version, kind가 표현하는 resource type
- Namespaced resource와 cluster-scoped resource
- Schema validation과 defaulting
- 사용자가 선언한 의도와 시스템이 보고하는 현재 상태
- Identity를 이루는 field와 변경 가능한 구성 field의 차이

Client, API server, controller가 definition에서 각각 어떤 정보를 필요로 하는지 질문합니다.

### 4. Object identity 도출하기

다음 요소를 하나의 identity model로 연결합니다.

- Resource type, namespace, name
- Generated name
- UID와 삭제 후 재생성된 object의 구분
- 설명적 identity로 사용하는 label
- 동적인 관계를 만드는 selector
- Lifecycle과 controller 관계를 표현하는 owner reference
- Controller ownership과 garbage collection

Name만으로 identity를 완전히 표현할 수 없는 이유, label만으로 ownership을 표현할 수 없는 이유를 탐구합니다.

### 5. Controller lineage 따라가기

하나의 Deployment에서 시작해 다음 관계를 도출하고 확인합니다.

- Deployment의 identity와 desired state
- Desired state를 실현하기 위해 선택되거나 생성되는 ReplicaSet
- ReplicaSet이 소유하는 Pod
- 이 관계를 연결하는 label과 selector
- Service와 그 Service가 선택하는 Pod
- Rollout 과정에서 바뀌는 name 또는 hash
- 삭제하고 다시 만들었을 때 유지되는 관계와 달라지는 관계

생성된 resource의 name, UID, owner, label, selector를 임의로 정해진 YAML 값으로 여기지 않고 그 이유를 설명할 수 있어야 합니다.

### 6. Application과 platform 사이의 contract 살펴보기

같은 workload로 다음 내용을 탐구합니다.

- Configuration과 secret reference
- 리소스 request와 limit
- Readiness
- Graceful termination
- Replica 변경과 rollout

각 선언이 controller의 판단에 어떤 영향을 주며, Kubernetes가 애플리케이션에 기대하는 동작은 무엇인지 질문합니다.

### 7. Reconciliation 관찰하기

다음과 같은 변경이나 실패를 준비합니다.

- 관리 중인 Pod를 삭제합니다.
- 원하는 replica 수를 변경합니다.
- Pod template을 변경합니다.
- Readiness를 실패하게 만듭니다.
- 같은 name으로 object를 다시 만듭니다.

결과를 확인하기 전에 identity, ownership, 컨트롤러 책임을 근거로 어떤 일이 생길지 먼저 예측합니다.

## 범위

### 반드시 다룰 내용

- Declarative API와 control loop
- Desired state, observed state, convergence
- 최소한의 이미지 빌드
- Pod, Deployment, ReplicaSet, 서비스 관계
- Resource definition과 API identity
- Name, UID, label, selector, owner reference
- Configuration, resource, readiness, shutdown을 application contract로 보는 관점
- Reconciliation 실험

### 다루지 않을 내용

- Virtual machine과의 비교
- Container 런타임 내부 구조
- 세부 Dockerfile 최적화
- 모든 workload 타입 소개
- Storage와 scheduling 심화
- 광범위한 YAML 문법 수업
- Platform이 생성하는 naming 규칙: Part 2와 GitOps에서 다룹니다.

## 시작 자료

- [Kubernetes Objects](https://kubernetes.io/docs/concepts/overview/working-with-objects/)
- [Object Names and IDs](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/)
- [Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
- [Owners and Dependents](https://kubernetes.io/docs/concepts/overview/working-with-objects/owners-dependents/)
- [Controllers](https://kubernetes.io/docs/concepts/architecture/controller/)
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)

## 최소 준비 사항

- Kubernetes의 철학과 resource identity를 중심으로 세션을 진행합니다.
- 조사에 사용한 참고 자료를 공유합니다.
