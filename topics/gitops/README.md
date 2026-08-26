# GitOps

[전체 커리큘럼으로 돌아가기](../../README.md)

## 기본 정보

- **대상:** 애플리케이션 개발자
- **담당 인원:** 2명
- **시간:** 120분

## 학습 목표

새 애플리케이션 저장소를 만들고 [SystemConsultantGroup/kubernetes](https://github.com/SystemConsultantGroup/kubernetes)에 연결하는 과정을 익힙니다. 이어서 Managed application이 배포되는 전체 lifecycle을 이해합니다.

세션이 끝났을 때 참가자는 클러스터 또는 플랫폼 운영자 권한 없이도 정해진 절차에 따라 애플리케이션을 onboarding할 수 있어야 합니다.

## 준비 방향

Managed application의 가장 기본적인 성공 경로 하나를 준비합니다. Production 배포는 처음부터 끝까지 추적하고, testing과 pull-request preview는 production과 달라지는 부분만 설명합니다.

두 저장소와 여러 시스템을 연결해서 보되, 모든 workflow, ApplicationSet, Helm template의 내부 구현을 분석하는 세션으로 만들지는 않습니다. 핵심 철학은 ownership입니다. Source, build artifact, deployment intent, runtime state에 대한 권한이 각각 어느 저장소와 시스템에 있는지 구분합니다.

## 시작 자료

Kubernetes 저장소의 다음 파일부터 살펴봅니다.

- `applications/README.en.md`
- `applications/example/`
- `.github/workflows/README.en.md`
- `argocd/application-sets/README.en.md`
- `argocd/charts/application/README.en.md`

문서에서 workflow를 직접 도출하되, 적힌 내용을 그대로 옮기지 말고 GitOps model과 연결해 설명합니다.

## 탐구 방향

### 1. 두 저장소 사이의 계약 정의하기

다음 질문을 조사합니다.

- Application repository에는 무엇이 있어야 하는가?
- Kubernetes repository에는 무엇이 있어야 하는가?
- 어느 저장소가 delivery event를 시작하는가?
- 어느 저장소가 deployment intent를 기록하는가?
- 런타임 state를 source of truth로 다시 기록하지 않는 이유는 무엇인가?
- 한 저장소가 다른 저장소에 변경을 요청할 수 있도록 허용하는 authorization은 무엇인가?

개별 workflow를 살펴보기 전에 trust boundary부터 그립니다.

### 2. 최소 Application repository 준비하기

작은 예제 저장소를 만들거나 모의 환경을 구성하고 다음을 확인합니다.

- 어떤 application artifact를 build할 수 있어야 하는가?
- Dockerfile과 build context는 어디에 있어야 하는가?
- Shared workflow는 어떻게 참조하고 version을 고정하는가?
- 어떤 workflow event가 배포와 관련되는가?
- 어떤 권한과 credential이 필요한가?
- 어떤 값을 build input으로 안전하게 넘길 수 있는가?
- Workflow 또는 image에 절대 포함하면 안 되는 정보는 무엇인가?

기존 production application을 변경하기보다 일회용 예제를 사용합니다.

### 3. Managed application 등록하기

Kubernetes 저장소의 managed layout을 살펴보며 다음을 조사합니다.

- Application과 workload의 intent를 어떤 파일이 정의하는가?
- Application metadata에는 어떤 정보가 들어가는가?
- Instance lock에는 어떤 정보가 들어가는가?
- 최초 production identity는 어떻게 만들어지는가?
- Source identity와 이미지 identity는 어떻게 연결되는가?
- 저장소, Argo CD, 네임스페이스, Kubernetes에 걸친 naming 제약은 무엇인가?
- 이 contract는 어떤 validation으로 보호되는가?

Custom Kustomize layout은 escape hatch로만 간단히 소개합니다. 어떤 상황에서 추가 조사가 필요한지 판단할 기준을 제시합니다.

### 4. Production 배포 하나 추적하기

Production 변경 하나를 처음부터 끝까지 따라갑니다.

1. Application source가 변경됩니다.
2. Application repository의 delivery workflow가 실행됩니다.
3. Immutable build artifact와 source identity가 생성됩니다.
4. 저장소 간 요청이 인증되고 검증됩니다.
5. Kubernetes repository의 deployment intent가 변경됩니다.
6. Argo CD가 새로운 상태를 관찰합니다.
7. 애플리케이션 생성과 Helm rendering이 이루어집니다.
8. Kubernetes가 생성된 resource를 reconcile합니다.

각 전환에서 이동하는 아티팩트, 변경 권한을 가진 주체, identity, 가능한 실패를 식별합니다.

정확한 이벤트 mapping과 워크플로 behavior는 커리큘럼에서 정답으로 받는 것이 아니라, 저장소 문서를 통해 준비팀이 직접 찾아야 합니다.

### 5. Testing과 preview의 차이 조사하기

Production 흐름을 이해한 뒤 다음을 조사합니다.

- 어떤 event가 testing 배포를 식별하는가?
- 어떤 event가 preview를 식별하는가?
- Preview identity는 어떻게 파생되는가?
- Preview를 갱신하거나 닫으면 어떤 일이 생기는가?
- Preview는 어떤 configuration 또는 service를 공유할 수 있는가?
- Production과 다른 security assumption은 무엇인가?

전체 production 흐름을 반복하지 말고 차이만 정리합니다.

### 6. 리소스 생성 과정과 연결하기

Kubernetes Part 2에서 배운 내용을 이용해 다음을 확인합니다.

- 애플리케이션 선언은 어떻게 Argo CD Application이 되는가?
- Shared values와 template은 어느 지점에 들어오는가?
- 예제 workload를 위해 어떤 resource가 만들어지는가?
- 생성된 identity는 애플리케이션 identity와 어떻게 연결되는가?

ApplicationSet과 차트 template을 줄마다 분석하지는 않습니다.

### 7. 설계 철학 평가하기

마지막으로 다음 질문을 논의합니다.

- 불변 source identity와 이미지 identity가 중요한 이유는 무엇인가?
- Workflow가 cluster를 직접 바꾸지 않고 Git을 변경하는 이유는 무엇인가?
- 애플리케이션 개발자에게 cluster credential이 필요하지 않은 이유는 무엇인가?
- 신뢰할 수 없는 application event는 어떤 제약을 받는가?
- 두 저장소에 걸쳐 어떤 audit trail이 남는가?
- 이 속성을 얻는 대신 어떤 failure mode를 감수하는가?

## 범위

### 반드시 다룰 내용

- Managed application 하나의 onboarding
- Application repository 구성
- Shared workflow 연결
- 저장소 간 authorization과 trust
- 불변 source 및 이미지 identity
- Kubernetes 저장소 최초 등록
- Production lifecycle 전체
- Testing과 preview의 차이
- ApplicationSet과 Helm generation의 큰 흐름

### 다루지 않을 내용

- Custom Kustomize onboarding 상세
- Reusable workflow 내부 구현
- Shared chart template 내부 구현
- Argo CD 플랫폼 관리
- 플랫폼 recovery
- Production 자격 증명 또는 실제 production 변경

## 최소 준비 사항

- Managed application onboarding과 lifecycle을 중심으로 세션을 진행합니다.
- 조사에 사용한 참고 자료를 공유합니다.

일회용 example repository 또는 충분히 설득력 있는 simulation을 준비하면 좋지만 필수는 아닙니다.
