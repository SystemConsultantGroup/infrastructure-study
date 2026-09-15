# 2026 인프라 스터디 커리큘럼

Linux와 네트워크의 기초부터 Kubernetes와 플랫폼 운영까지, 현대 인프라를 이루는 기술의 **철학과 설계 배경**을 공부하는 학생 주도 스터디입니다.

모든 차시에서 가장 중요하게 다룰 질문은 단순히 “이 도구를 어떻게 사용하는가?”가 아닙니다. **어떤 문제를 해결하기 위해 등장했는가, 어떤 철학으로 설계되었는가, 그 선택으로 무엇을 얻고 무엇을 감수하는가**를 이해하는 것이 목표입니다.

## 진행 방식

- 각 주제는 120분 진행을 기준으로 구성합니다.
- 주제를 배정받은 학생이 직접 조사하고 스터디를 진행합니다.
- 일반 주제는 애플리케이션 개발자에게 필요한 관점을 다룹니다.
- Advanced 주제는 플랫폼 엔지니어에게 필요한 관점을 다룹니다.
- 필수 결과물은 준비한 세션과 공유할 참고 자료뿐입니다. 슬라이드, 다이어그램, 실습, 과제 등을 만들지는 각 팀이 자유롭게 결정합니다.
- 주제별 문서는 정답을 제공하지 않고, 조사를 시작할 방향과 질문을 제시합니다. 결론은 공식 문서와 직접 수행한 실험을 바탕으로 준비팀이 도출해야 합니다.
- SCG 환경을 살펴볼 때는 [SystemConsultantGroup/kubernetes](https://github.com/SystemConsultantGroup/kubernetes) repository를 기준으로 합니다.

## 커리큘럼

각 제목은 해당 차시의 학습 목표와 준비 방향을 담은 상세 문서로 연결됩니다.

| 차시 | 인원 | 제목 | 담당자 |
| --- | ---: | --- | --- |
|  | 2명 | [Introduction + Docker](topics/introduction/README.md) | 박준성(31기), |
|  | 2명 | [MAC / IP / TCP](topics/mac-ip-tcp/README.md) | 양호준(31기), 손희창(31기) |
|  | 3명 | [Linux Network Stack (Advanced)](topics/linux-network-stack/README.md) | 
|  | 2명 | [HTTP / TLS / DNS](topics/http-tls-dns/README.md) | 이찬형(31기), 최연우 (31기) |
|  | 3명 | [Kubernetes (Part 1)](topics/kubernetes-part-1/README.md) |  김상현(26기), 이현우(27기) |
|  | 2명 | [Talos (Advanced)](topics/talos/README.md) | |
|  | 3명 | [Kubernetes (Part 2)](topics/kubernetes-part-2/README.md) | 권승원 (31기), 김상현(26기),  |
|  | 2명 | [GitOps](topics/gitops/README.md) | 이찬형(31기), 이진우(31기) |
|  | 3명 | [GitOps (Advanced)](topics/gitops-advanced/README.md) | | 

## 준비 원칙

모든 준비팀은 다음 네 가지 질문에 답할 수 있어야 합니다.

1. 이 기술은 어떤 문제를 해결하기 위해 만들어졌는가?
2. 이 기술을 가장 잘 설명하는 mental model은 무엇인가?
3. 어떤 trade-off와 책임 경계를 만드는가?
4. 문서를 그대로 옮기는 데 그치지 않고, 이해한 내용을 어떻게 검증할 수 있는가?

공식 문서에 적힌 사실, 실험에서 직접 관찰한 결과, 준비팀이 추론한 내용을 명확히 구분해야 합니다. 참고 자료는 공식 문서, 표준 문서, 소스 코드, 그리고 이 스터디에서 직접 다루는 repository를 우선합니다.

## 개발 환경

다음 명령으로 스터디 개발 환경에 진입할 수 있습니다.

```sh
nix develop
```

Flake에는 각 차시에서 사용할 수 있는 최소한의 공통 도구가 들어 있습니다. DNS, HTTP/TLS, container, Kubernetes, Cilium, Talos/QEMU, GitHub, YAML, throughput 측정, packet observation 도구를 제공하며, Linux에서는 low-level 주제에 필요한 Linux 전용 networking 및 tracing 도구가 추가됩니다.

지원 환경은 x86_64 Linux, aarch64 Linux, aarch64 macOS입니다. macOS 지원은 Flake가 정상적으로 평가되고 환경을 이식할 수 있음을 확인하는 데 주된 목적이 있습니다. operating system 기능에 의존하는 실습은 Linux가 필요할 수 있습니다. Flake는 `nixpkgs-unstable` branch를 사용합니다.
