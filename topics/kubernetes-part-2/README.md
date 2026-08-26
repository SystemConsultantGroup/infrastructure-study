# Kubernetes (Part 2)

[전체 커리큘럼으로 돌아가기](../../README.md)

## 기본 정보

- **대상:** 애플리케이션 개발자
- **담당 인원:** 3명
- **시간:** 120분

## 학습 목표

Helm, Argo CD, Gateway API가 Kubernetes의 선언적 모델을 packaging, Git reconciliation, application routing 영역으로 어떻게 확장하는지 이해합니다.

세션이 끝났을 때 참가자는 하나의 application input이 세 시스템을 거치는 과정을 추적하고, 각 변환과 판단을 어느 시스템이 책임지는지 구분할 수 있어야 합니다.

## 준비 방향

Helm, Argo CD, Gateway API를 담당할 주 조사자를 한 명씩 정하되, 세 개의 독립된 발표가 아니라 하나의 흐름으로 준비합니다.

각 시스템에 대해 같은 질문을 던집니다.

- 어떤 문제를 해결하는가?
- 어떤 mental model을 도입하는가?
- 어떤 input과 state를 소유하는가?
- 무엇을 생성하거나 reconcile하는가?
- 책임은 어디에서 끝나는가?

## 탐구 방향

### 1. 하나의 애플리케이션을 기준으로 삼기

SCG Kubernetes 저장소에서 간단한 애플리케이션 선언 하나를 선택합니다. 처음부터 생성되는 모든 resource를 알려주지 말고, 애플리케이션 개발자가 직접 관리하는 input부터 확인합니다.

최종적으로 다음 흐름을 하나로 연결합니다.

1. 애플리케이션 입력
2. Helm rendering
3. Argo CD reconciliation
4. Kubernetes resource
5. Gateway API routing
6. Backend Service

이 흐름을 이용해 변환, reconciliation, runtime behavior의 경계를 드러냅니다.

### 2. Helm의 역할 탐구하기

다음 질문을 조사합니다.

- Helm은 어떤 반복과 변형을 관리하기 위해 만들어졌는가?
- Chart, values, template, rendered manifest는 어떤 관계인가?
- Resource가 Kubernetes에 전달되기 전에 무엇을 검증할 수 있는가?
- Helm은 자신이 rendering한 resource를 지속적으로 관리하는가?
- Shared chart는 어떤 조건에서 유용한 application contract가 되는가?
- Abstraction이 오히려 중요한 내용을 가리는 시점은 언제인가?

작은 rendering 예제를 하나 준비합니다. Template language 수업으로 확장하지 말고, 전체 흐름에 필요하지 않다면 helper function도 다루지 않습니다.

### 3. Argo CD의 역할 탐구하기

다음 질문을 조사합니다.

- Argo CD는 Part 1에서 다룬 controller와 reconciliation model을 어떻게 Git까지 확장하는가?
- Argo CD Application은 무엇을 식별하는가?
- 어떤 desired state와 observed state를 비교하는가?
- Sync, health, drift는 어떻게 구분해야 하는가?
- 생성된 manifest가 유효하지 않거나 실제 상태가 수렴하지 못하면 어떤 일이 생기는가?
- 애플리케이션 개발자와 플랫폼 운영자의 책임은 어디에서 나뉘는가?

Argo CD 관리 방법, UI 사용법, Project, 고급 sync behavior는 GitOps (Advanced)에서 다룹니다.

### 4. Gateway API의 역할 탐구하기

다음 질문을 조사합니다.

- 어떤 한계 때문에 Gateway API가 등장했는가?
- Resource model은 infrastructure와 application의 ownership을 어떻게 나누는가?
- Listener, route, backend는 어떤 관계인가?
- Route는 어떤 조건에서 Gateway에 attach될 수 있는가?
- Host와 path에 따른 결정은 어떻게 표현되는가?
- TLS는 어느 지점에서 terminate될 수 있는가?
- API 선언을 실제 runtime behavior로 만드는 controller는 무엇인가?

선택한 애플리케이션에 필요한 라우팅 기능만 사용합니다. 고급 filter와 cross-namespace 설계는 선택 사항입니다.

### 5. 세 시스템 연결하기

전체 흐름의 각 전환마다 다음을 판단합니다.

- 이 단계는 rendering, reconciliation, admission, controller action, request processing 중 무엇인가?
- 경계를 넘는 artifact 또는 API resource는 무엇인가?
- 한 번만 실행되는 과정인가, 지속적으로 반복되는 과정인가?
- Input과 output의 identity를 무엇이 연결하는가?
- 실패는 어디에서 관찰할 수 있는가?
- 문제를 조사할 때 어느 시스템부터 확인해야 하는가?

세 시스템이 Kubernetes control model을 대체하는 것이 아니라 서로 다른 영역에서 보완한다는 점이 드러나야 합니다.

## 범위

### 반드시 다룰 내용

- 하나로 이어지는 애플리케이션 lifecycle
- Helm 차트, values, 템플릿, rendering 개념
- Argo CD Application과 reconciliation 개념
- Gateway API ownership과 기본 HTTP 라우팅 model
- 생성되는 Kubernetes resource와 identity 전환
- 각 시스템의 책임 및 장애 경계

### 다루지 않을 내용

- 세부 Helm 템플릿 문법
- Argo CD 관리 방법
- Argo CD Project와 플랫폼 reconciliation 구조
- 고급 Gateway API filter와 matching
- 세 시스템 각각의 독립된 전체 시연
- Application repository onboarding: GitOps에서 다룹니다.

## 시작 자료

- [Helm: Charts](https://helm.sh/docs/topics/charts/)
- [Helm: Chart Template Guide](https://helm.sh/docs/chart_template_guide/)
- [Argo CD Core Concepts](https://argo-cd.readthedocs.io/en/stable/core_concepts/)
- [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/)
- [SystemConsultantGroup/kubernetes](https://github.com/SystemConsultantGroup/kubernetes)의 application example, shared application chart, ApplicationSet, 관련 route

저장소 경로는 조사의 출발점일 뿐, 생성 흐름에 대한 결론을 미리 제공하는 정답은 아닙니다.

## 최소 준비 사항

- 세 시스템을 하나의 흐름으로 연결한 세션을 진행합니다.
- 조사에 사용한 참고 자료를 공유합니다.
