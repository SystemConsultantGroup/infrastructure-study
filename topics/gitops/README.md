# GitOps

[전체 커리큘럼으로 돌아가기](../../README.md)

## 기본 정보

- **대상:** 애플리케이션 개발자
- **담당 인원:** 2명
- **시간:** 120분

## 학습 목표

애플리케이션 repository를 [SystemConsultantGroup/kubernetes](https://github.com/SystemConsultantGroup/kubernetes)의 관리형 배포 흐름에 연결하는 방법과 그 배경을 이해합니다.

클러스터를 직접 변경하는 권한 없이도 애플리케이션을 등록하고 배포할 수 있는 이유를 ownership, identifiers, 신뢰의 관점에서 설명하는 것이 목표입니다.

## 준비 방향

관리형 애플리케이션의 기본 경로를 중심으로 준비합니다. 운영 환경 배포의 전체 흐름을 살펴보고, 테스트 환경과 Pull Request preview는 운영 환경과 다른 점을 필요한 범위에서 비교합니다.

repository 문서를 출발점으로 삼되, 개별 workflow나 템플릿을 줄마다 설명하지 않습니다. 사용할 예제와 시연 범위는 준비팀이 선택합니다.

## 탐구 주제

### 두 repository의 책임

- 애플리케이션 repository와 Kubernetes repository는 각각 어떤 상태를 소유하는가?
- 소스, 빌드 artifacts, 배포 의도, 실행 상태는 어디에 속하는가?
- 한 repository가 다른 repository에 변경을 요청할 때 어떤 신뢰와 권한이 필요한가?
- 실행 중인 클러스터 상태를 다시 Git의 기준 상태로 취급하지 않는 이유는 무엇인가?

### 애플리케이션 repository 준비

- 관리형 배포 흐름에 참여하려면 애플리케이션 repository가 어떤 계약을 만족해야 하는가?
- 빌드와 배포 workflow는 어떤 입력, identifiers, 권한을 다루는가?
- 공통 workflow를 사용할 때 애플리케이션 팀과 플랫폼 팀의 책임은 어떻게 나뉘는가?
- 인증 정보나 신뢰할 수 없는 입력을 다룰 때 어떤 제약이 필요한가?

작은 예제 repository나 모의 환경을 사용할 수 있지만 필수는 아닙니다. 실제 운영 환경을 변경하거나 운영 인증 정보를 사용하지 않습니다.

### 관리형 애플리케이션 등록

- Kubernetes repository에서 애플리케이션의 배포 의도는 어떻게 표현되는가?
- 애플리케이션, 이미지, namespace, Argo CD Application의 identifiers는 어떻게 연결되는가?
- repository가 제공하는 공통 추상화는 무엇을 표준화하는가?
- 기본 경로를 벗어난 구성이 필요할 때 누가 어떤 책임을 가져야 하는가?

### 배포 흐름 추적

운영 환경의 변경 하나를 골라 소스 변경부터 Kubernetes reconciliation까지의 경로를 직접 도출합니다.

- 각 경계에서 어떤 이벤트와 artifacts가 이동하는가?
- 누가 변경을 만들고, 검증하고, 승인하고, 관찰하는가?
- 변경되지 않는 소스 및 이미지 identifiers는 어디에서 만들어지고 이어지는가?
- 실패는 어느 repository나 시스템에서 확인할 수 있는가?

정확한 순서와 구현은 repository 문서와 실제 workflow를 통해 확인합니다. 이 문서의 질문을 체크리스트처럼 모두 답할 필요는 없습니다.

### 환경별 차이와 설계 평가

- 운영, 테스트, preview 환경은 identifiers와 lifecycle에서 어떻게 다른가?
- Git을 통한 변경이 직접 클러스터를 바꾸는 방식보다 어떤 장점과 비용을 가지는가?
- 애플리케이션 개발자에게 클러스터 인증 정보를 주지 않는 구조는 어떤 신뢰 경계를 만드는가?
- 두 repository와 여러 시스템에 걸쳐 어떤 감사 기록이 남는가?

## 범위

### 핵심 범위

- 관리형 애플리케이션 등록 과정
- 애플리케이션 repository와 Kubernetes repository의 책임
- 공통 workflow와 repository 사이의 신뢰
- 소스 및 이미지 identifiers
- 운영 환경 배포의 전체 흐름
- 테스트와 preview 환경의 주요 차이

### 범위 밖

- 별도 Kustomize 방식의 세부 구현
- 공통 workflow와 Helm 템플릿 내부 구현
- Argo CD 플랫폼 운영
- 운영 환경 변경, 인증 정보, 복구 절차

## 참고 자료

- [SystemConsultantGroup/kubernetes](https://github.com/SystemConsultantGroup/kubernetes)
- repository의 애플리케이션 등록, workflow, Argo CD 구성에 관한 문서와 예제

## 준비 결과

- 위 목표를 다루는 120분 세션
- 조사에 사용한 참고 자료

예제 repository, 다이어그램, 모의 시연의 포함 여부는 준비팀이 결정합니다.
