# Kubernetes (Part 2)

[전체 커리큘럼으로 돌아가기](../../README.md)

## 기본 정보

- **대상:** 애플리케이션 개발자
- **담당 인원:** 3명
- **시간:** 120분

## 학습 목표

Helm, Argo CD, Gateway API가 Kubernetes의 선언적 모델을 각각 어떤 방향으로 확장하는지 이해합니다. 하나의 애플리케이션이 세 시스템을 거치는 과정에서 변환, reconciliation, 라우팅의 책임을 구분할 수 있는 것이 목표입니다.

## 준비 방향

세 기술을 독립된 기능 소개로 나누기보다 공통된 애플리케이션 사례로 연결합니다. 사례와 역할 분담, 설명 순서는 준비팀이 자유롭게 정할 수 있습니다.

각 기술에 대해 어떤 문제를 해결하는지, 어떤 상태를 소유하는지, 책임이 어디에서 끝나는지를 중심으로 살펴봅니다.

## 탐구 주제

### 공통 흐름

- 애플리케이션 개발자가 직접 관리하는 입력은 무엇인가?
- 입력은 어떤 단계에서 다른 형태의 리소스로 바뀌는가?
- 일회성 변환과 지속적인 reconciliation은 어떻게 다른가?
- 배포된 리소스와 실제 요청 처리 사이의 경계는 어디인가?

### Helm

- 반복되는 Kubernetes 선언을 관리하기 위해 Helm은 어떤 모델을 제공하는가?
- 차트, `values`, 템플릿, 렌더링된 매니페스트는 어떻게 연결되는가?
- 공통 차트는 언제 유용한 계약이 되고, 언제 중요한 세부 사항을 가리는가?
- 렌더링 단계에서 알 수 있는 오류와 알 수 없는 오류는 무엇인가?

### Argo CD

- Argo CD는 Kubernetes의 reconciliation 모델을 Git과 어떻게 연결하는가?
- Application이 가리키는 원하는 상태와 클러스터에서 관찰된 상태는 무엇인가?
- `sync`, `health`, `drift`는 서로 어떤 차이가 있는가?
- 애플리케이션 개발자와 플랫폼 운영자의 책임은 어디에서 나뉘는가?

### Gateway API

- Gateway API는 어떤 소유권과 협업 문제를 해결하려 하는가?
- `Gateway`, `Listener`, `Route`, `backendRef`의 관계는 어떻게 표현되는가?
- 선언한 `Route`가 실제 요청 처리로 이어지려면 어떤 컨트롤러와 상태가 필요한가?
- 라우팅과 TLS 책임은 배포 구조에 따라 어떻게 달라지는가?

### 세 시스템 연결하기

준비팀은 [SystemConsultantGroup/kubernetes](https://github.com/SystemConsultantGroup/kubernetes)에서 사례 하나를 골라 Helm, Argo CD, Kubernetes, Gateway API 사이의 흐름을 도출합니다.

각 경계에서 이동하는 선언과 리소스, 식별 정보의 연결, 관찰할 수 있는 실패를 설명합니다. 저장소 구조를 그대로 소개하기보다 각 시스템의 책임이 드러나도록 구성합니다.

## 범위

### 핵심 범위

- 하나의 애플리케이션으로 연결한 전체 흐름
- Helm의 패키징과 렌더링 방식
- Argo CD Application과 reconciliation
- Gateway API의 소유권과 기본 라우팅 모델
- 세 시스템 사이의 책임 및 장애 경계

### 범위 밖

- Helm 템플릿 문법 심화
- Argo CD 운영 및 관리 방법
- Argo CD Project와 플랫폼 전체 reconciliation 구조
- Gateway API의 고급 필터와 매칭 기능 전반
- 애플리케이션 저장소 등록 절차

## 참고 자료

- [Helm: Charts](https://helm.sh/docs/topics/charts/)
- [Helm: Chart Template Guide](https://helm.sh/docs/chart_template_guide/)
- [Argo CD Core Concepts](https://argo-cd.readthedocs.io/en/stable/core_concepts/)
- [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/)
- [SystemConsultantGroup/kubernetes](https://github.com/SystemConsultantGroup/kubernetes)의 애플리케이션 예제, 공통 차트, ApplicationSet, 관련 Route

저장소는 조사의 출발점이며, 준비팀은 실제 생성 흐름을 직접 확인합니다.

## 준비 결과

- 위 목표를 다루는 120분 세션
- 조사에 사용한 참고 자료

사례, 다이어그램, 렌더링 또는 라우팅 시연의 포함 여부는 준비팀이 결정합니다.
