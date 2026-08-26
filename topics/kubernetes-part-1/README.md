# Kubernetes (Part 1)

[전체 커리큘럼으로 돌아가기](../../README.md)

## 기본 정보

- **대상:** 애플리케이션 개발자
- **담당 인원:** 3명
- **시간:** 120분

## 학습 목표

Kubernetes를 리소스 목록이 아니라 선언적 API와 컨트롤러가 만드는 제어 시스템으로 이해합니다. 리소스의 식별 정보와 소유 관계를 바탕으로 하나의 워크로드가 어떻게 구성되고 유지되는지 설명할 수 있는 것이 목표입니다.

## 준비 방향

Kubernetes의 철학과 reconciliation 모델을 먼저 세우고, 필요한 리소스를 사례로 도입합니다. 하나의 간단한 애플리케이션을 계속 사용해도 되고, 개념별로 다른 사례를 선택해도 됩니다.

YAML 작성법보다 **왜 이런 리소스와 관계가 필요한가**에 초점을 맞춥니다. 아래 질문의 순서와 깊이는 준비팀이 조정할 수 있습니다.

## 탐구 주제

### 선언적 제어 시스템

- 명령으로 동작을 지시하는 방식과 원하는 상태를 선언하는 방식은 어떻게 다른가?
- API 서버와 컨트롤러는 각각 어떤 책임을 맡는가?
- 원하는 상태(desired state), 관찰된 상태(observed state), reconciliation은 어떻게 연결되는가?
- 수렴이 늦어지거나 실패할 때 시스템과 애플리케이션의 책임은 어떻게 나뉘는가?

### 리소스 정의와 식별 정보

- `apiVersion`, `kind`, `metadata`, `spec`, `status`는 무엇을 표현하는가?
- 리소스 종류, `namespace`, `name`, `UID`는 오브젝트를 어떻게 식별하는가?
- `label`과 `selector`는 어떤 관계를 만들며, 식별 정보와는 어떻게 다른가?
- `ownerReferences`는 생명주기와 컨트롤러의 소유 관계를 어떻게 표현하는가?

리소스 종류, `namespace`/`name`, `UID`, `label`/`selector`, `ownerReferences`를 서로 떨어진 용어가 아니라 하나의 식별 모델로 연결합니다.

### 컨트롤러와 리소스 관계

- 하나의 워크로드 선언을 유지하기 위해 어떤 컨트롤러와 리소스가 협력하는가?
- Deployment, ReplicaSet, Pod, Service의 관계는 어디에 표현되는가?
- 롤아웃이나 재생성 과정에서 유지되는 식별 정보와 바뀌는 식별 정보는 무엇인가?
- 독립적으로 동작하는 컨트롤러들이 충돌하지 않으려면 어떤 경계가 필요한가?

### 애플리케이션과 플랫폼의 계약

- 이미지와 Kubernetes 선언은 각각 어떤 정보를 담아야 하는가?
- 설정, 리소스 요청량, 준비 상태(readiness), 정상 종료(graceful shutdown)는 컨트롤러의 판단에 어떤 신호를 주는가?
- Kubernetes가 대신 해결해 주는 문제와 애플리케이션에 남는 책임은 무엇인가?

### Reconciliation 관찰

준비팀은 삭제, replica 수 변경, 롤아웃, readiness 실패, 재생성 등에서 일부를 골라 reconciliation을 관찰할 수 있습니다. 결과를 먼저 보여주기보다 식별 정보와 소유 관계를 근거로 예상한 뒤 실제 상태와 비교하는 방식이 좋습니다.

## 범위

### 핵심 범위

- 선언적 API와 제어 루프
- 원하는 상태, 관찰된 상태, 수렴
- Kubernetes 리소스 정의
- `name`, `UID`, `label`, `selector`, `ownerReferences`
- 워크로드를 구성하는 컨트롤러와 소유 관계
- 애플리케이션과 플랫폼의 책임 경계

### 범위 밖

- 컨테이너 런타임 내부 구조
- 모든 워크로드 및 리소스 종류 소개
- 스토리지와 스케줄링 심화
- 광범위한 YAML 문법 수업
- 플랫폼 저장소가 리소스를 생성하는 세부 과정

## 참고 자료

- [Kubernetes Objects](https://kubernetes.io/docs/concepts/overview/working-with-objects/)
- [Object Names and IDs](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/)
- [Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
- [Owners and Dependents](https://kubernetes.io/docs/concepts/overview/working-with-objects/owners-dependents/)
- [Controllers](https://kubernetes.io/docs/concepts/architecture/controller/)
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)

## 준비 결과

- 위 목표를 다루는 120분 세션
- 조사에 사용한 참고 자료

사례와 관찰 실습의 구성은 준비팀이 결정합니다.
