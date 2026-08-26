# GitOps (Advanced)

[전체 커리큘럼으로 돌아가기](../../README.md)

## 기본 정보

- **대상:** 플랫폼 엔지니어
- **담당 인원:** 3명
- **시간:** 120분

## 학습 목표

SCG Kubernetes 저장소를 플랫폼의 source of truth로 이해하고, root reconciliation 구조, trust boundary, `k`를 통한 운영 작업, 대표적인 장애 상황을 안전하게 판단하는 방법을 익힙니다.

모든 platform component를 외우거나 완전한 disaster-recovery manual을 만드는 것이 아니라, 시스템 전체를 설명할 수 있는 운영 모델을 세우는 것이 목표입니다.

## 준비 방향

선언적 reconciliation과 bootstrap, 변경, 복구 과정에서 여전히 필요한 imperative 작업 사이의 경계를 중심으로 세션을 구성합니다.

저장소와 `k --help`를 1차 근거로 사용합니다. 이 주제를 준비하거나 진행하는 동안 production cluster에 mutating 또는 destructive command를 실행해서는 안 됩니다.

## 시작 자료

다음 파일과 디렉터리에서 조사를 시작합니다.

- `README.en.md`
- `state.yaml`
- `flake.nix`
- `argocd/root-application.yaml`
- `argocd/application-sets/`
- `argocd/projects/`
- `argocd/charts/application/`
- `argocd/platform/`
- `patches/README.en.md`
- `scripts/k`
- `scripts/k.commands/`
- `.github/workflows/`

디렉터리를 순서대로 소개하지 말고, 책임과 trust boundary를 기준으로 구조를 다시 그립니다.

## 탐구 방향

### 1. Source of truth 구분하기

다음 질문을 조사합니다.

- 어떤 desired state가 Git에 속하는가?
- Rendering 또는 reconciliation 중에 파생되는 상태는 무엇인가?
- Talos, Kubernetes, Argo CD, 외부 시스템에만 존재하는 상태는 무엇인가?
- 어떤 generated artifact를 별도의 source of truth처럼 직접 수정하면 안 되는가?
- Operator는 어느 선언을 수정해야 하는지 어떻게 판단하는가?
- Source of truth처럼 보이는 두 상태가 서로 다를 때 무엇을 기준으로 해야 하는가?

Cluster state, platform state, application state를 연결하는 hierarchy를 만듭니다.

### 2. Root reconciliation 따라가기

Root에서 시작해 다음을 알아봅니다.

- Argo CD는 나머지 desired state를 어떻게 발견하는가?
- 어떤 resource가 다른 Application을 생성하거나 소유하는가?
- Application concern과 platform concern은 어떻게 분리되는가?
- Authorization boundary는 어디에서 강제되는가?
- Shared application contract는 reconciliation 구조에 어디에서 들어오는가?
- 단순한 apply 순서만으로 해결할 수 없는 dependency는 무엇인가?
- Reconciliation에 필요한 컨트롤러 또는 CRD가 없다면 어떤 일이 생기는가?

모든 platform component를 소개하지 말고, 구조를 설명하는 데 적합한 대표 branch만 선택합니다.

### 3. Validation과 변경 안전성 탐구하기

다음 질문을 조사합니다.

- Merge 전에 어떤 검사를 수행할 수 있는가?
- 어떤 잘못된 상태는 rendering 또는 admission 단계에서야 발견되는가?
- Formatting은 style 통일 외에 어떤 역할을 하는가?
- Naming, identity, 저장소 invariant 가운데 무엇을 검증하는가?
- 자동화로 확인할 수 없어 review에 남는 전제는 무엇인가?
- 추적 중인 branch에 merge하면 운영 측면에서 어떤 결과가 발생하는가?

가능하다면 안전한 local check를 직접 실행하고, repository validation과 cluster-side validation을 구분합니다.

### 4. Secret과 trust boundary 그리기

실제 값이 아니라 시스템 구조를 중심으로 다음을 조사합니다.

- Git에는 어떤 secret material이 어떤 형태로 존재할 수 있는가?
- 어떤 key 또는 identity가 이를 decrypt하거나 materialize할 수 있는가?
- Application runtime value와 repository metadata는 어떻게 분리되는가?
- 어느 시스템이 plaintext에 접근해야 하는가?
- Recipient와 access 변경은 어떻게 review되는가?
- Secret 컨트롤러 또는 backing service를 사용할 수 없으면 어떤 실패가 발생하는가?

실제 secret을 노출하지 않고 trust relationship과 장애 동작에 집중합니다.

### 5. `k`가 존재하는 이유 이해하기

Command interface를 읽으며 다음을 질문합니다.

- 어떤 운영 복잡성을 감추거나 표준화하는가?
- 각 command는 저장소의 어떤 상태를 input으로 사용하는가?
- 단순히 관찰하거나 검증하는 command는 무엇인가?
- Machine, cluster, secret store, repository를 변경하는 command는 무엇인가?
- 파괴적이거나 recovery 목적의 command는 무엇인가?
- 일반적인 Argo CD reconciliation으로 수행할 수 없는 작업은 무엇인가?
- Imperative 작업이 끝난 뒤 시스템은 어떻게 declared state로 돌아가는가?

대표 command를 다음과 같이 분류합니다.

1. Observational
2. Validating
3. Mutating
4. Destructive
5. Recovery-oriented

전체 command reference를 만드는 것은 목표가 아닙니다.

### 6. Bootstrap 경계 탐구하기

선언적 platform에 존재하는 순환 dependency처럼 보이는 문제를 조사합니다.

- Argo CD가 어떤 것도 reconcile하기 전에 무엇이 준비되어야 하는가?
- Secret을 materialize하기 전에 무엇이 있어야 하는가?
- Platform controller가 자신의 resource를 처리하기 전에 무엇이 필요한가?
- 어떤 단계는 반드시 imperative할 수밖에 없는가?
- 그 단계가 끝난 뒤 ownership은 어떻게 reconciliation에 넘겨지는가?
- Cluster를 재현하려면 어떤 state가 필요한가?

Bootstrap을 단순한 명령 순서가 아니라 dependency와 state transition으로 표현합니다.

### 7. 장애 사례 두 가지 분석하기

다음과 같은 사례 중 두 개를 고릅니다.

- Merge된 플랫폼 변경이 수렴하지 않습니다.
- 필요한 secret을 materialize할 수 없습니다.
- Node를 교체해야 합니다.
- Upgrade가 일부만 성공했습니다.
- 수동 개입 후 Git state와 cluster state가 달라졌습니다.

각 사례에서 다음을 판단합니다.

- 권위 있는 desired state는 무엇인가?
- 어떤 evidence를 수집해야 하는가?
- 안전하게 관찰할 수 있는 절차는 무엇인가?
- Reconciliation을 계속 허용할지, 잠시 멈출지, 먼저 복구할지 어떻게 결정하는가?
- `k`가 필요한가? 필요하다면 위험도는 어느 수준인가?
- 다시 이해 가능하고 일관된 desired state를 어떻게 만드는가?
- 복구 완료는 무엇으로 확인하는가?

Production runbook을 완성하는 것이 아니라, 일관된 판단 절차를 만드는 것이 목표입니다.

## 범위

### 반드시 다룰 내용

- Root reconciliation hierarchy
- Application과 platform의 책임 경계
- Validation과 merge의 운영 영향
- Secret trust model
- `k`의 목적과 위험도 분류
- 선언적 작업과 불가피한 imperative 작업의 차이
- Bootstrap dependency
- 장애 사례 두 가지

### 다루지 않을 내용

- 모든 platform component 나열
- Argo CD UI 또는 관리 방법
- 완전한 `k` command catalogue
- 완전한 disaster-recovery runbook
- 실제 destructive operation
- Production secret value
- GitOps에서 이미 다룬 애플리케이션 onboarding 상세

## 최소 준비 사항

- 운영 모델과 장애 판단을 중심으로 세션을 진행합니다.
- 조사에 사용한 참고 자료를 공유합니다.

Command 시연이 필요하다면 read-only, local, 또는 disposable environment에서만 진행합니다.
