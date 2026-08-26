# 2026 Infrastructure Study Curriculum

A student-led study of the ideas behind modern infrastructure, progressing from Linux and networking fundamentals to Kubernetes and platform operations.

The central question in every session is not merely _how does this tool work?_, but _what problem does it solve, what philosophy shaped it, and what trade-offs follow from that philosophy?_

## Format

- Each topic is designed for a 120-minute session.
- The students assigned to a topic research it and lead the session.
- Non-advanced sessions target application developers.
- Advanced sessions target platform engineers.
- A prepared session and shared references are the only mandatory outputs. Slides, diagrams, exercises, and labs are left to each group.
- The topic documents contain investigation vectors, not answers. Groups should derive conclusions from primary sources and experiments.
- Repository-specific investigations use [SystemConsultantGroup/kubernetes](https://github.com/SystemConsultantGroup/kubernetes).

## Curriculum

| 차시 | 제목 | 목적 | 내용 | 인원 배정 |
| --- | --- | --- | --- | ---: |
|  | [Introduction](topics/introduction/README.md) | Establish the common Linux/Nix environment and understand reproducible, declarative environments. | Set up Linux; install Determinate Nix; compare imperative and declarative setup; enter and inspect the provided study environment; demonstrate the path from a fresh environment to a working shell. | 2 |
|  | [MAC / IP / TCP](topics/mac-ip-tcp/README.md) | Reason about host-to-host communication through the link, network, and transport layers. | Investigate layering, addressing, neighbours, routing, ICMP, and the TCP lifecycle; use `ip` and `ping` to test hypotheses; treat additional diagnostic tools as optional research. | 2 |
|  | [Linux Network Stack (Advanced)](topics/linux-network-stack/README.md) | Trace a TCP read/write through Linux and extend the model to Cilium-backed Kubernetes. | Follow data through syscalls, sockets, TCP, kernel buffers, routing, queues, devices, and receive processing; investigate namespace and eBPF integration; derive one representative Kubernetes path without assuming its configuration. | 3 |
|  | [HTTP / TLS / DNS](topics/http-tls-dns/README.md) | Explain the high-level journey from a URL to an authenticated HTTP response. | Build one end-to-end request flow; investigate DNS delegation and caching, TLS identity and trust, and application-relevant HTTP semantics; compare protocol versions only through their motivations. | 2 |
|  | [Kubernetes (Part 1)](topics/kubernetes-part-1/README.md) | Understand Kubernetes as a declarative control system and reason about resource identity and ownership. | Study desired and observed state, reconciliation, resource definitions, names and UIDs, labels and selectors, owner references, and controller-derived resources; validate the model with one application. | 3 |
|  | [Talos (Advanced)](topics/talos/README.md) | Understand Talos's design philosophy and the lifecycle of an API-managed Kubernetes node. | Investigate Talos's operating model, machine configuration, bootstrap, change, and recovery concepts; use a disposable QEMU node and `talosctl` to validate the theory. | 2 |
|  | [Kubernetes (Part 2)](topics/kubernetes-part-2/README.md) | Understand how Helm, Argo CD, and Gateway API extend Kubernetes packaging, reconciliation, and routing. | Trace one application through Helm rendering, Argo CD reconciliation, Kubernetes resources, and Gateway API routing; identify each system's philosophy, state, and responsibility boundary. | 3 |
|  | [GitOps](topics/gitops/README.md) | Set up an application repository and connect it to the SCG Kubernetes delivery workflow. | Follow the managed application path from repository setup and immutable image creation through cross-repository updates and deployment generation; cover production fully and summarize testing and preview behavior. | 2 |
|  | [GitOps (Advanced)](topics/gitops-advanced/README.md) | Understand and safely reason about the platform's reconciliation and operational model. | Map the root reconciliation hierarchy and trust boundaries; investigate validation and secrets; classify `k` operations; distinguish declarative reconciliation from necessary imperative work; analyze representative incidents. | 3 |

## Preparation expectations

Every preparation group should be ready to address four questions:

1. What problem motivated this solution?
2. What mental model best explains it?
3. What trade-offs and responsibility boundaries does it create?
4. How can the group validate its understanding rather than merely repeat documentation?

Groups should clearly distinguish documented facts, experimental observations, and their own inferences. Shared references should prefer official documentation, standards, source code, and this study's target repositories.

## Tooling status

A small cross-platform Nix Flake will be added after the curriculum and topic documents are accepted. It will target x86_64 and aarch64 on Linux and macOS; macOS support is intended primarily to demonstrate evaluation and environment portability.
