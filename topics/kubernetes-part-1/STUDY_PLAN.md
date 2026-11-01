# Kubernetes Part 1 스터디 상세 계획

[주제별 학습 목표](README.md) · [전체 커리큘럼](../../README.md)

## 목표와 진행 방식

발표자 2명이 120분 동안 진행합니다. 참가자는 2인 1조로 로컬 k3s에 작은 HTTP 서버를 배포하고, Pod 교체와 롤아웃, Service 연결과 readiness를 관찰합니다. 마지막에는 같은 서버를 내부 클러스터에 배포할 때 확인할 사항을 정리합니다.

기본적인 Docker 지식과 Introduction에서 Nix 개발 셸을 사용해 본 경험을 전제로 합니다. **k3s 클러스터 설치와 기본 설정, 이미지 다운로드, Headlamp 접속은 스터디 전에 마칩니다.**

실습은 **제공된 skeleton 실행 → 결과와 관련 개념 이해 → 기존 파일 확인·수정 → 재적용과 관찰** 순서로 진행합니다. 처음에는 완성된 예제를 그대로 실행하고, 이후 필요한 개념을 설명한 다음 같은 서버와 매니페스트를 점진적으로 변경합니다. 매 실험 전에 결과를 예상하고 실제 관찰과 비교합니다.

## 1. 발표자별 준비

| 구분 | 발표자 A: 선언과 연결 | 발표자 B: 상태 유지와 애플리케이션 계약 |
| --- | --- | --- |
| 핵심 질문 | 어떤 선언과 관계로 서버를 실행하고 서로 연결하는가? | controller가 선언을 어떻게 유지하며, 수렴 실패와 요청 처리에 앱은 어떤 책임을 지는가? |
| 담당 개념 | Kubernetes 필요성, 선언적 API, Pod·ReplicaSet·Deployment 기초, 식별과 소유 관계, Service·label·selector | desired/observed state와 수렴, ReplicaSet·Deployment controller의 경계, scaling·rollout, readiness, 앱과 플랫폼의 계약 |
| 주요 활동 | workload skeleton 실행·Pod 교체, Service skeleton 실행·selector 장애 복구 | replica 변경 시연, 롤아웃과 수렴 실패·오류 시연, readiness 실험, 내부 배포 비교 |
| 준비 자료 | `lab/service.yaml`, HTTP 클라이언트, 식별·트래픽 관찰 질문과 해설, k3d·Headlamp 사전 설정 안내 | `lab/workload.yaml`, 앱 이미지, replica·rollout·readiness 실험과 Headlamp 오류 시연, 내부 클러스터 예제 |
| 공통 합의 | 앱 이미지와 endpoint, 리소스 이름·label, 포트, namespace, probe와 초기 replica 수를 먼저 확정 | 정상 동작하는 skeleton과 각 실습의 시작·종료 상태를 A와 공유 |

A는 합의한 workload skeleton을 사용해 Pod 교체와 Service 실습을 준비합니다. B는 Service 없이 workload와 Pod 상태로 scaling·롤아웃을 준비하고, readiness 실험에는 합의된 Service skeleton을 사용합니다. 두 파일의 초기 버전을 일찍 공유하면 각자 로컬 클러스터에서 대부분 독립적으로 준비할 수 있습니다. 통합 리허설은 한 번 진행하고, 한 사람이 발표할 때 다른 사람은 참가자의 실습을 돕습니다. 직접 진행 시간은 A 53분, B 48분이며 공동 휴식·내부 배포 비교·마무리는 19분입니다. A가 전반부를 진행한 뒤 휴식 시간에 B에게 한 번 인계합니다.

## 2. 공통 서버와 skeleton 계약

팀별 메시지와 revision, Pod 이름을 보여 주는 작은 stateless HTTP 서버를 사용합니다. 참가자는 먼저 제공된 기본 응답을 확인하고, 이후 workload 파일의 설정을 수정해 각 조의 메시지를 배포합니다.

| 항목 | 준비할 내용 |
| --- | --- |
| 리소스 | 조별 namespace, Deployment `team-server`, Service `team-server` |
| 선택 관계 | Pod template에 `app: team-server` label, Service에 같은 selector |
| 포트 | 컨테이너 HTTP `8080`, 포트 이름 `http`, Service 포트 `80` → `http` |
| 설정 | Pod template의 `TEAM_NAME`, `MESSAGE`, `REVISION` 환경 변수 |
| `GET /` | 팀 메시지, revision, Pod 이름 반환. 외부 의존성 없음 |
| `GET /ready` | 평소 `200`, `/tmp/not-ready`가 있으면 `503` 반환 |
| 상태 제어 | 선택한 Pod에 표시 파일을 만들고 지우는 명령 제공 |
| 이미지 | 로컬과 내부 환경에서 접근 가능한 레지스트리에 미리 게시하고 검증한 digest로 고정 |
| Replica | skeleton은 1개. B가 2개로 늘렸다가 1개로 되돌려 시연하고, readiness 실험 직전에 각 조가 2개로 변경 |
| 종료 처리 | SIGTERM 수신 시 새 작업 수신을 멈추고 진행 중인 요청을 정해진 시간 안에 마무리 |
| 리소스 | requests CPU `25m` / 메모리 `32Mi`, limits `250m` / `128Mi`를 출발점으로 선택한 런타임에서 검증 |

위 앱, 이미지, 매니페스트와 실습용 HTTP 클라이언트는 **준비팀이 만들어야 할 결과물**입니다. 현재 계획만으로 구현된 것은 아닙니다. 참가자가 매니페스트 전체를 작성하거나 수업 중 이미지를 빌드하지 않도록 바로 적용 가능한 workload와 Service skeleton을 제공합니다. 가능하면 Introduction 앱을 재사용하고 필요한 식별·readiness 동작만 추가합니다. DB, 로그인, 볼륨, 커스텀 도메인과 Helm chart 작성은 다루지 않습니다.

Readiness probe가 필수입니다. Liveness와 startup probe는 역할 차이만 짧게 설명하고, 실패 시연은 선택 사항입니다. Readiness가 graceful shutdown이나 무중단 배포까지 보장하는 것은 아닙니다.

## 3. 사전 준비: 로컬 k3s와 Headlamp

로컬 Kubernetes에는 Docker에서 k3s를 실행하는 k3d를 사용합니다. 독립적인 [실습용 flake](lab/flake.nix)는 `k3d`, `kubectl`, `curl`, Docker 클라이언트를 제공합니다. Nix는 Docker daemon을 시작하지 않으므로 Introduction에서 사용한 Docker 런타임을 준비합니다. Docker Desktop을 사용하면 Linux 컨테이너 백엔드를 사용합니다.

스터디 전에 저장소 최상위 경로에서 다음을 실행합니다.

```bash
cd topics/kubernetes-part-1/lab
nix develop path:.
docker info
k3d cluster create infra-study --servers 1 --agents 0 --wait --timeout 120s \
  --kubeconfig-update-default=false --kubeconfig-switch-context=false
export KUBECONFIG="$PWD/.kubeconfig.local"
k3d kubeconfig get infra-study > "$KUBECONFIG"
kubectl get nodes
```

kubeconfig는 로컬에 보관하고 Git으로 추적하지 않습니다. 실습 터미널마다 같은 `KUBECONFIG`와 실습용 flake를 사용해 기존 내부 클러스터 context를 변경하지 않도록 합니다. 최종 참가자 안내에서는 리허설한 k3s 이미지를 k3d의 `--image`로 고정하고, 가능하면 내부 클러스터와 가까운 Kubernetes minor 버전을 선택합니다. 서버·HTTP 클라이언트 이미지를 미리 받아 두고 참가자의 CPU 아키텍처에서 확인합니다. 게시된 이미지를 사용해 로컬과 내부 환경의 이미지 배포 경로를 비슷하게 유지합니다.

**Headlamp:** 클러스터 리소스와 오류 상태를 쉽게 살펴보도록 준비팀은 사전에 공식 Helm chart로 각 로컬 실습 클러스터에 Headlamp를 설치하고 접속을 검증합니다. 실습용 flake에 Helm이 아직 포함되어 있지 않으므로 준비팀은 실습 flake에 Helm을 추가하거나 참가자가 사용할 별도 Helm 설치 경로를 제공해야 합니다. 설치와 설정은 이번 계획의 준비 항목이며 아직 구현되지 않았습니다.

로컬 실습 계정에는 만료되지 않는 토큰을 준비합니다. Kubernetes에서는 ServiceAccount와 연결된 수동 token Secret을 이용할 수 있으며, RBAC는 실습 namespace와 필요한 조회 권한으로 제한합니다. 토큰은 로컬에서만 사용하고 저장소에 기록하지 않으며 실습 종료 시 Secret과 계정을 삭제합니다. 이 방식은 내부 클러스터의 인증 방식으로 일반화하지 않습니다. Kubernetes 공식 문서는 장기 토큰보다 단기 토큰을 권장합니다. Headlamp와 토큰 설정, namespace 접근 및 브라우저 연결을 사전 점검하고 오류 시에는 `kubectl` 관찰로 진행할 수 있게 합니다.

단일 노드 클러스터로 controller 동작은 관찰할 수 있지만 노드 장애에 대한 가용성을 검증하지는 못합니다. 당일 설정이 5분 이상 지연되면 정상 동작하는 조와 짝을 이루고 발표자 환경이나 기록된 출력을 대안으로 사용합니다.

## 4. 120분 진행 계획

A가 전반부를, B가 후반부를 연속해서 진행하고 휴식 시간에 한 번 인계합니다. 각 파트에서 skeleton 실행, 개념 설명, 기존 파일과 실행 상태 확인, 수정·재적용을 차례로 연결합니다. 참가자의 예상과 관찰을 짧게 공유하고, 휴식 시간에 조별 키보드 담당과 관찰 담당을 바꿉니다.

### 0–10분 · A · 왜 Kubernetes가 필요할까?

- **문제 제기:** 서버 한 대에 직접 배포하거나 Docker로 컨테이너를 실행할 때 장애 복구, 증설, 업데이트, 접속 경로를 누가 관리하는지 질문합니다. 서버와 서비스가 늘어나면 여러 머신에 걸친 반복 작업과 조정이 필요합니다.
- **개념:** Kubernetes의 선언적 API와 controller는 원하는 상태를 유지하는 운영 작업을 지원합니다. 클러스터 운영과 리소스 모델의 복잡성도 생기므로 작은 단일 서버에 항상 필요한 것은 아닙니다.
- **참여 질문:** “서버 하나가 사라져도 원하는 수를 유지하려면 무엇이 필요할까요?” 실습 목표와 사전 준비 상태를 확인합니다.

### 10–18분 · A · workload skeleton 실행

- 조별 namespace에 준비된 `lab/workload.yaml`을 **수정 없이** 적용합니다. Pod 상태를 확인하고 제공된 Pod port-forward 명령으로 기본 서버 응답을 엽니다.
- Headlamp에서 Deployment와 Pod를 찾아봅니다. 이때는 port-forward와 도구의 역할만 간단히 설명하고 매니페스트의 모든 필드를 해설하지 않습니다.
- 이후 같은 파일을 읽고 수정한다는 점을 안내합니다. Pod port-forward는 선택한 Pod에 직접 연결하며 Service의 부하 분산을 검증하지 않습니다.

### 18–33분 · A · Pod, ReplicaSet, Deployment와 reconciliation

- **Pod:** 하나 이상의 컨테이너를 함께 실행하는 기본 단위입니다. **ReplicaSet:** 지정된 Pod 수를 유지하며, 일반적으로 이 실습에서는 Deployment가 만듭니다. ReplicaSet 자체를 깊이 다루기보다 Pod와 Deployment를 잇는 역할에 집중합니다.
- **Deployment:** 원하는 Pod template과 replica 수를 선언하고 ReplicaSet을 관리하며 업데이트를 진행합니다. ReplicaSet은 주로 개수를 유지하고 Deployment는 template 변경 시 새 ReplicaSet을 이용해 롤아웃합니다.
- 방금 적용한 파일의 `apiVersion`, `kind`, `metadata`, `spec`과 조회한 `status`를 연결합니다. API 서버·controller의 역할, 원하는 상태와 관찰된 상태, 수렴, namespace/name과 UID를 간단히 소개합니다.
- 이름이 같아도 삭제 후 새로 생성한 오브젝트는 UID가 다릅니다. Label은 이름이나 UID처럼 특정 인스턴스를 식별하는 값이 아니라 selector로 집합을 찾기 위한 속성입니다. 뒤에서 Service selector와 비교합니다.
- Deployment → ReplicaSet → Pod의 `ownerReferences`를 Headlamp와 `kubectl`에서 확인합니다. Pod 이름·UID와 소유자를 기록하고 삭제 결과를 예상한 뒤 삭제합니다. 새 Pod의 UID와 복구된 replica 수를 비교합니다. ReplicaSet controller가 대체 Pod를 만듭니다.

### 33–43분 · A · Service skeleton 실행하고 이해하기

- 준비된 `lab/service.yaml`을 **수정 없이** 적용하고 미리 준비한 클러스터 내부 HTTP 클라이언트에서 `http://team-server/`에 요청합니다.
- Service가 클러스터 내부 서비스들이 서로 연결할 때 사용할 안정적인 접근 지점을 제공하고, label/selector로 백엔드 Pod를 선택하는 원리를 설명합니다. EndpointSlice에서 백엔드 주소와 상태를 확인합니다.
- 이미 적용한 Service 파일의 selector, Pod label, EndpointSlice를 비교합니다. 리소스 종류·namespace/name은 오브젝트를 찾고 UID는 특정 인스턴스를 구분하며, label/selector는 조건에 맞는 집합을 선택합니다. Service는 Pod를 선택하지만 소유하지는 않습니다. 반복 요청은 별도 연결로 보내고 반드시 round-robin으로 분배된다고 가정하지 않습니다.

### 43–53분 · A · Service selector 장애와 복구

- Pod가 정상이어도 Service selector가 일치하지 않으면 백엔드가 없을 수 있음을 설명합니다.
- 기존 Service 파일에서 selector만 잘못된 값으로 바꿔 재적용합니다. Pod label → Service selector → EndpointSlice를 비교하고, 같은 파일을 다시 수정해 복구한 뒤 클러스터 내부 클라이언트로 정상 응답을 확인합니다.

### 53–58분 · 공동 · 휴식과 인계

조별 담당을 바꾸고 소유 관계와 선택 관계를 간단히 그립니다. 각 조는 정상 Service와 replica 1개인 Deployment를 유지합니다. B는 이 상태를 출발점으로 이어서 진행합니다.

### 58–68분 · B · controller와 replica 변경 시연

- A가 관찰한 Pod 교체를 이어 받아 Deployment controller는 ReplicaSet을, ReplicaSet controller는 Pod 수를 조정한다는 책임 경계를 설명합니다. 각 controller는 자신의 대상과 원하는 상태를 감시하고 독립적으로 동작합니다.
- `ownerReferences`로 관리 관계를 확인하고 selector가 겹치는 controller가 같은 Pod를 두고 충돌할 수 있음을 설명합니다. 서로 다른 workload의 selector를 겹치지 않게 구성하고, Deployment가 관리하는 ReplicaSet의 replica 수를 별도 자동화가 계속 바꾸지 않도록 책임을 구분합니다. 이 충돌은 설명 사례로만 다룹니다.
- 선언된 수가 원하는 상태이고 실제 상태가 따라오는 데 시간이 걸리거나 실패할 수 있음을 설명합니다. 발표자가 기존 workload 파일의 replicas를 1에서 2로 변경해 재적용하고 desired/ready 수를 비교합니다. 참가자는 변화를 보고 이유를 설명합니다. 시연은 1개로 되돌립니다.

### 68–78분 · B · 기존 파일 업데이트와 수렴 실패 관찰

- 참가자는 workload 파일의 `MESSAGE`나 `REVISION`을 바꿔 다시 적용합니다. Pod template이 변경되면 새 ReplicaSet이 만들어지고 Pod가 교체되는 것을 관찰합니다. Deployment는 같은 오브젝트로 유지됩니다.
- Headlamp에서 이전 ReplicaSet의 replica가 0개로 남는 사례를 보여 줍니다. 이전 revision의 ReplicaSet은 롤백 이력으로 보존될 수 있으며, 보존 수와 정리 여부는 Deployment 설정과 상태에 따라 다릅니다.
- 발표자는 별도 시연 환경에서 준비한 이미지 오류 또는 롤아웃 오류를 Headlamp의 상태와 이벤트로 보여 주고 원인을 확인합니다. 참가자의 정상 배포를 망가뜨리지 않도록 복구된 결과도 함께 보여 줍니다.
- 원하는 replica 수가 선언되어도 이미지를 가져올 수 없거나 앱이 준비되지 않으면 Ready 상태로 수렴하지 못할 수 있습니다. Kubernetes는 상태·이벤트를 보여 주고 계속 조정하지만, 유효한 이미지와 정상 동작하는 앱을 제공할 책임은 준비팀에 있습니다.

### 78–92분 · B · readiness와 트래픽 대상

- 각 조가 기존 workload 파일의 replicas를 2로 수정해 재적용하고 두 Pod가 Ready가 될 때까지 확인합니다. B는 앞선 replica 시연을 복습하며 이 단계를 안내합니다.
- Running과 Ready의 차이를 설명하고 기존 workload 파일에 준비된 readiness probe를 확인합니다. Readiness는 앱이 제공하는 신호이며 플랫폼이 Service 트래픽 대상 판단에 사용합니다.
- 두 Ready Pod 중 하나에 `/tmp/not-ready`를 만들어 `/ready`를 실패시킵니다. Pod Ready 상태, 재시작 횟수와 EndpointSlice condition의 변화를 확인한 뒤 새 Service 요청을 보냅니다. 표시 파일을 지우고 복구합니다.
- Readiness 실패는 반드시 프로세스 재시작을 뜻하지 않습니다. Endpoint 주소는 `ready: false`로 계속 보일 수 있습니다. 전파 시간을 기다리고 새 요청과 기존 연결을 구분합니다.

### 92–106분 · B · 앱과 플랫폼의 책임

- 이미지와 실행 설정, requests/limits, SIGTERM과 graceful shutdown을 설명합니다. 실제 skeleton에서 관련 필드를 찾고, 실습에서 확인한 사실과 설명만 하는 동작을 구분합니다.
- 이미지는 실행 코드와 기본 실행 환경을 담고, 선언은 이미지 참조와 환경별 설정·자원·probe 등을 지정합니다. Scheduler는 requests를 고려해 배치하며 readiness는 요청을 받을 준비의 신호입니다. 앱은 올바른 신호와 종료 처리를 구현해야 하며 Kubernetes가 비즈니스 로직의 정합성을 대신 보장하지 않습니다.
- 참가자는 기존 workload 파일의 메시지나 revision을 다시 바꾸어 배포하고 replicas 2개와 Service 응답을 확인합니다. 종료 동작 실험은 선택 사항입니다.

### 106–115분 · 공동(B 주도) · 내부 클러스터로 연결

같은 Deployment·Service와 이미지가 다른 클러스터에서도 어떤 역할을 하는지 짚습니다. B가 준비된 내부 예제와 비교해 context, namespace·권한, 레지스트리, 보안 정책, 허용된 변경 경로와 route 필요 여부를 설명하고 A가 Service 연결 관점을 보탭니다. 실제 내부 배포는 배정된 실습 환경과 허용된 경로가 준비된 경우에만 선택적으로 진행합니다.

### 115–120분 · 공동 · 마무리와 정리

각 조가 Pod 교체와 Service 장애에서 관찰한 사실을 설명하고 자기 조의 실습 리소스를 정리합니다. 정식 보고서는 요구하지 않습니다.

**시간이 부족하면:** 명령형 scale 비교, 종료 동작 추가 실험, 마지막 추가 revision 변경을 생략합니다. skeleton 실행, 개념 설명과 기존 파일 관찰·수정, Pod 교체, Service 장애·readiness 및 내부 클러스터 비교는 유지합니다.

## 5. 발표자 관찰 메모

### 소유 관계와 식별

```text
Deployment --소유--> ReplicaSet --소유--> Pod
Service --label 일치로 선택--> Pod
EndpointSlice --Service의 백엔드 주소와 readiness 표현
```

Namespace가 있는 리소스의 이름은 리소스 종류와 namespace 범위에서 구분되고 UID는 오브젝트 인스턴스를 구분합니다. ReplicaSet이 만든 대체 Pod는 보통 다른 생성 이름을 가지며 UID는 반드시 다릅니다. API 서버는 선언을 저장·검증하고, controller는 조정하며, scheduler는 노드를 배정하고, kubelet은 컨테이너를 실행합니다.

Replica 수 변경은 새 Pod-template revision을 만들지 않습니다. 메시지·revision 환경 변수처럼 Pod template을 바꾸면 롤아웃이 시작됩니다. Revision 간 `app: team-server` label은 유지하며 Deployment selector를 롤아웃 대상으로 변경하지 않습니다. 선언 파일을 이번 실습의 원하는 상태 기준으로 삼았을 때, 명령형으로 2개로 늘린 뒤 replicas 1이 적힌 파일을 재적용하면 다시 1개를 요청합니다.

### Service와 readiness 확인

```bash
kubectl -n "$LAB_NS" get pods --show-labels
kubectl -n "$LAB_NS" get service team-server -o yaml
kubectl -n "$LAB_NS" get endpointslices \
  -l kubernetes.io/service-name=team-server -o yaml
```

Service 트래픽 실험에는 고정된 이미지의 클러스터 내부 HTTP 클라이언트를 사용합니다. `kubectl port-forward service/team-server 8080:80`도 선택된 Pod 하나에 직접 전달하므로 Service 데이터 경로의 부하 분산이나 readiness 기반 라우팅 근거로 사용하지 않습니다. 선택된 Pod가 없어지면 port-forward를 다시 시작합니다.

Readiness의 정확한 전파 시간과 트래픽 결과는 리허설에서 확인한 관찰값으로 기록합니다. 적절한 신호가 없으면 Kubernetes는 앱이 요청을 처리할 준비가 되었는지 알 수 없습니다.

## 6. 내부 클러스터 배포 시 비교

| 항목 | 로컬 k3s | 내부 클러스터 |
| --- | --- | --- |
| 도구·workload | 같은 Kubernetes API, `kubectl`, Deployment·Service와 probe | 정책이 허용하면 같은 명령과 선언을 사용하고 필요한 보안 설정만 조정 |
| Namespace·권한 | 조별 임시 namespace | 배정된 namespace와 권한 사용. Namespace 생성 권한을 가정하지 않음 |
| 이미지 | 게시된 이미지와 검증한 digest | 레지스트리 접근, 아키텍처, pull 자격 증명 확인 |
| 네트워크 | 클러스터 내부 HTTP 클라이언트, 브라우저는 port-forward | 허용된 진단 경로와 승인된 내부·외부 route 확인 |
| 정책 | 로컬 실습 환경 | requests/limits, security context, quota, NetworkPolicy, DNS와 admission 확인 |
| 변경 경로 | 실습 리소스에 직접 apply | 직접 apply 또는 플랫폼 관리형 배포 중 허용된 경로 확인 |

준비팀은 내부 클러스터의 실제 문서와 설정을 확인하고 관리자와 배정된 실습 환경을 검토합니다. 플랫폼 저장소가 있다는 사실만으로 특정 권한이나 route를 가정하지 않습니다. GitOps가 리소스를 관리한다면 허용된 변경 제출 경로를 설명하고 상세 흐름은 이후 차시에서 다룹니다. 필수 실습은 로컬에서 끝나며 실제 내부 배포와 기존 route를 통한 URL 시연은 선택 사항입니다.

직접 apply가 허용된 경우에만, 승인된 context와 기존 namespace를 확인한 뒤 사용할 수 있는 예시입니다. 아래 파일은 준비팀이 작성할 skeleton이며, `topics/kubernetes-part-1/lab` 디렉터리에서 실행합니다.

```bash
kubectl --context "$INTERNAL_CONTEXT" -n "$INTERNAL_NAMESPACE" \
  apply -f workload.yaml -f service.yaml
kubectl --context "$INTERNAL_CONTEXT" -n "$INTERNAL_NAMESPACE" \
  rollout status deployment/team-server --timeout=120s
```

재사용할 workload·Service 파일에는 namespace를 고정하지 않아 `-n`으로 두 환경에서 사용할 수 있게 합니다. Namespace 생성 매니페스트는 분리하고 환경별 변경은 작고 명확하게 유지합니다.

## 7. 준비와 완료 기준

**초기 합의:** 약 20분 동안 공통 앱·리소스 계약, 이미지 담당자, 내부 클러스터 실습 환경과 문의 담당자를 정합니다. 이후 각 발표자는 독립적으로 준비합니다.

**사전 제공:** skeleton 2개와 앱 이미지, 로컬 k3d·Headlamp와 Helm 설치 안내, 실습 계정과 접근 절차, 이미지 pull·클라이언트 안내, namespace 생성·정리 명령, readiness 전환 명령, 예상 기록지와 해설을 준비합니다. 참가자의 클러스터 접근, 이미지 pull, Headlamp 접속을 미리 확인합니다.

**통합 리허설:** 120분 시간표와 참가자 플랫폼별 실행, 두 replica로의 전환, namespace별 격리, 리소스 사용량, 오류 시연·복구를 확인합니다. 이미지 pull 실패나 Pending Pod를 대비해 스크린샷과 출력을 준비하되 기록된 자료임을 표시합니다. 로컬 성공과 내부 클러스터의 admission·네트워크·권한·라우팅 검증은 별개입니다.

**마무리 질문:**

1. Pod, ReplicaSet, Deployment는 각각 무엇을 책임지나요?
2. Pod를 삭제했을 때 새 UID가 생긴 이유는 무엇이며 누가 대체 Pod를 만들었나요?
3. Pod가 Running이어도 Service 요청이 실패할 수 있는 이유는 무엇인가요?
4. Readiness가 실패하면 요청 대상과 프로세스는 각각 어떻게 되나요?
5. 내부 배포에서 유지할 설정과 확인할 환경 차이는 무엇인가요?
6. 두 controller가 같은 workload를 조정할 때 selector와 소유 관계의 경계가 왜 필요한가요? Ready 수가 목표에 도달하지 않으면 플랫폼과 앱에서 각각 무엇을 확인하나요?

각 조는 정상 서버 응답, Ready replica 2개, 교체된 Pod의 UID, 복구한 Service 장애의 근거를 확인합니다. 로컬에서 조별 임시 namespace, port-forward·클라이언트, Headlamp 실습 계정과 토큰을 정리하고 필요하면 `k3d cluster delete infra-study`로 로컬 클러스터를 삭제합니다. 내부 실습 환경은 플랫폼의 소유 관계와 변경 경로에 따라 정리합니다.

## 참고 자료

- [k3d 개요와 Docker 요구 사항](https://k3d.io/stable/), [클러스터 생성 옵션](https://k3d.io/stable/usage/commands/k3d_cluster_create/)
- [K3s 빠른 시작](https://docs.k3s.io/quick-start)
- [Headlamp 설치 및 인증](https://headlamp.dev/docs/latest/installation/)
- [Kubernetes ServiceAccount와 장기 토큰](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/)
- [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [소유자와 종속 오브젝트](https://kubernetes.io/docs/concepts/overview/working-with-objects/owners-dependents/)
- [Kubernetes 오브젝트](https://kubernetes.io/docs/concepts/overview/working-with-objects/), [이름과 UID](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/), [label과 selector](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/), [controller](https://kubernetes.io/docs/concepts/architecture/controller/)
- [Service](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Readiness·liveness·startup probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [kubectl port-forward](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_port-forward/)
- [내부 플랫폼 저장소](https://github.com/SystemConsultantGroup/kubernetes)
