# HTTP / TLS / DNS

[전체 커리큘럼으로 돌아가기](../../README.md)

## 기본 정보

- **대상:** 애플리케이션 개발자
- **담당 인원:** 2명
- **시간:** 120분

## 학습 목표

URL을 입력한 순간부터 신뢰할 수 있는 HTTP 응답을 받기까지의 큰 흐름을 하나로 연결해 설명합니다. 각 프로토콜의 설계 철학과 애플리케이션 개발자가 알아야 할 HTTP semantics에 집중합니다.

세션이 끝났을 때 참가자는 DNS, TLS, HTTP를 따로 외운 상태가 아니라, 하나의 요청 안에서 세 프로토콜이 맡는 역할과 경계를 연결할 수 있어야 합니다.

## 준비 방향

대표 URL 하나를 정하고 클라이언트에서 애플리케이션까지 따라갑니다. 요청이 각 문제에 맞닥뜨리는 시점에 DNS, TLS, HTTP를 차례로 도입합니다.

이론과 전체 흐름을 중심으로 준비합니다. 도구를 이용해 일부 단계를 확인할 수는 있지만, 패킷 분석이나 암호 알고리즘 구현은 범위에 포함하지 않습니다.

## 탐구 방향

### 1. End-to-end 요청 흐름 정의하기

다음 요소를 포함하는 sequence diagram을 구성합니다.

- 클라이언트 애플리케이션
- 로컬 및 recursive name resolution
- DNS authority
- Transport connection
- TLS negotiation
- HTTP intermediary 또는 Gateway
- 목적지 애플리케이션

항상 필요한 단계, 캐시하거나 재사용할 수 있는 단계, 프로토콜 버전 또는 배포 구조에 따라 달라지는 단계를 구분합니다.

### 2. Naming system으로서의 DNS 이해하기

다음 질문을 조사합니다.

- 이름과 주소를 별도로 관리하는 이유는 무엇인가?
- Authority는 어떻게 분산되고 위임되는가?
- Recursive resolver와 authoritative server는 각각 어떤 일을 하는가?
- 어떤 정보가 어디에, 얼마나 오래 캐시되는가?
- 선택한 요청에는 어떤 record가 필요한가?
- 오래되거나 서로 다른 응답이 나타나는 이유는 무엇인가?
- 어떤 실패를 DNS 문제로 분류해야 하며, 애플리케이션 문제와 어떻게 구분하는가?

DNSSEC과 resolver 내부 구현은 핵심 범위에서 제외합니다.

### 3. Trust protocol로서의 TLS 이해하기

다음 질문을 조사합니다.

- TLS는 어떤 위협을 막으려 하는가?
- 클라이언트는 자신이 접속하려는 대상을 어떻게 식별하는가?
- 그 identity는 certificate와 chain of trust에 어떻게 연결되는가?
- HTTP를 시작하기 전에 무엇을 합의해야 하는가?
- SNI와 ALPN은 왜 필요한가?
- 어느 지점에서 TLS를 terminate할 수 있으며, termination 지점이 바뀌면 책임 경계는 어떻게 달라지는가?
- Transport 또는 HTTP 오류와 구분해야 할 TLS 오류는 무엇인가?

암호학적 동작은 보장하는 속성과 trust model을 이해하는 데 필요한 수준까지만 다룹니다.

### 4. HTTP semantics 탐구하기

애플리케이션 동작에 직접 영향을 주는 개념을 우선합니다.

- Method가 표현하는 의도
- Safety와 idempotency
- Status code와 redirect
- Header와 representation 메타데이터
- Authentication과 authorization 신호의 차이
- Cache와 검증
- Cookie와 browser state
- Browser security mechanism으로서의 CORS
- Proxy를 거치며 전달되는 정보와 신뢰 경계

구체적인 사례를 통해 API 또는 애플리케이션의 동작이 HTTP semantics에 부합하는지 검토합니다.

### 5. HTTP version을 등장 배경 중심으로 비교하기

HTTP/1.1, HTTP/2, HTTP/3에 대해 다음을 조사합니다.

- 다음 version이 해결하려 했던 한계는 무엇인가?
- Connection 사용과 multiplexing 방식은 어떻게 달라졌는가?
- Version이 바뀌어도 유지되는 application semantics는 무엇인가?
- 애플리케이션 개발자가 실제로 체감하거나 고려해야 할 차이는 무엇인가?

Frame format이나 transport 구현을 자세히 파고들지는 않습니다.

### 6. 실패의 책임 구분하기

다음과 같은 실패 사례를 준비하고, 어느 계층에서 책임을 찾아야 할지 분류합니다.

- 이름을 해석하지 못합니다.
- 오래된 응답이나 의도하지 않은 주소를 받습니다.
- Transport connection을 만들지 못합니다.
- Certificate identity 검증이 실패합니다.
- TLS negotiation이 실패합니다.
- Gateway가 요청을 거부하거나 route를 찾지 못합니다.
- 애플리케이션이 오류를 반환합니다.
- 서버 응답은 유효하지만 browser가 접근을 차단합니다.

Low-level 도구를 사용하기 전에 전체 흐름에서 문제 영역을 좁혀가는 습관을 만드는 것이 목표입니다.

## 범위

### 반드시 다룰 내용

- URL에서 응답까지 이어지는 하나의 이야기
- DNS delegation과 캐싱
- TLS identity, trust chain, SNI, ALPN
- HTTP method, status, 헤더, idempotency, redirect, 캐싱
- Cookie, CORS, proxy boundary
- 등장 배경 중심의 HTTP 버전 비교
- 장애가 발생한 영역을 프로토콜별로 구분하는 방법

### 다루지 않을 내용

- Packet capture 분석
- TLS 암호 primitive의 세부 구현
- TLS wire message 암기
- HTTP frame format의 세부 구조
- DNSSEC
- 모든 DNS record 나열
- HTTP version별 상세 benchmark

## 시작 자료

- [RFC 9110: HTTP Semantics](https://www.rfc-editor.org/rfc/rfc9110)
- [RFC 9111: HTTP Caching](https://www.rfc-editor.org/rfc/rfc9111)
- [RFC 8446: TLS 1.3](https://www.rfc-editor.org/rfc/rfc8446)
- [RFC 1034: Domain Names — Concepts and Facilities](https://www.rfc-editor.org/rfc/rfc1034)
- [MDN: HTTP](https://developer.mozilla.org/en-US/docs/Web/HTTP)
- [MDN: CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)

## 최소 준비 사항

- 전체 요청 흐름과 애플리케이션 semantics를 중심으로 세션을 진행합니다.
- 조사에 사용한 참고 자료를 공유합니다.
