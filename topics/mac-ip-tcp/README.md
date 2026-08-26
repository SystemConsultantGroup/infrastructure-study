# MAC / IP / TCP

[Back to the curriculum](../../README.md)

## Profile

- **Audience:** Application developers
- **Leads:** 2
- **Duration:** 120 minutes

## Purpose

Develop a theory-first model of host-to-host communication through the link, network, and transport layers.

By the end of the session, participants should be able to reason about where communication is failing and use `ip` and `ping` to test basic hypotheses. They should not need Kubernetes or container concepts to explain the path.

## Preparation brief

Use a small number of communication scenarios rather than presenting protocols independently. Begin with two hosts on the same network, introduce a routed destination, and finish with a TCP client and server.

Tools support the model; they are not the subject of the session.

## Guiding vectors

### 1. Explain why layers exist

Investigate:

- Which problem is assigned to each layer?
- Which identifiers are meaningful only on a local link, and which survive routing?
- What does each layer assume the layer below already provides?
- How does layering make independent evolution possible?
- Where does the clean model differ from implementation reality?

### 2. Trace local communication

For two hosts on the same network, determine:

- How the sender decides that the destination is local.
- Which addresses are needed to transmit data.
- How a network-layer destination becomes a link-layer next hop.
- What state the operating system must already know or discover.
- Which observations can be made with `ip`.

Use the scenario to connect interfaces, addresses, prefixes, routes, and neighbours.

### 3. Introduce routing

Extend the scenario to a destination outside the local network:

- How is a route selected?
- What does the default gateway represent?
- Which addresses change at each hop and which remain end to end?
- What happens when a route is absent or incorrect?
- What can a host know about the complete path?

Avoid turning subnet arithmetic into the main lesson; include only what is needed to reason about routing decisions.

### 4. Place ICMP in the model

Investigate what ICMP contributes to IP networking:

- What question does `ping` actually ask?
- Which conclusions can and cannot be drawn from a response or timeout?
- How do latency, loss, policy, and an unavailable destination differ?
- Why can an application fail even when `ping` succeeds?
- Why can `ping` fail while an application still works?

Prepare experiments with explicit hypotheses rather than a list of command flags.

### 5. Build the TCP mental model

Follow a TCP connection from the application's perspective:

- What abstraction does TCP expose to an application?
- How is a connection identified?
- What needs to happen before application data can flow?
- How are ordering, acknowledgement, retransmission, and flow control related?
- What happens during an orderly close?
- How should an application developer interpret timeout, refusal, and reset?

Cover congestion control only to the degree needed to understand TCP's responsibilities. Algorithm comparisons are outside the core scope.

### 6. Optional tool-research vector

If a preparation group member wants an additional practical vector, choose one or more tools and investigate their limits:

- `mtr` for path, latency, and loss over time
- `hping3` for controlled ICMP or TCP probes
- `iperf3` for throughput between controlled endpoints
- `ss` for local socket state
- `nc` for a minimal TCP client and server

For each selected tool, answer:

- What hypothesis can it test?
- What prerequisites or privileges does it need?
- What does its output not prove?
- Does it clarify the core model enough to justify session time?

These tools are optional; `ip` and `ping` are the only required practical tools.

## Scope boundaries

### Keep

- Layering and responsibility boundaries
- MAC and IP relationships
- Interfaces, prefixes, neighbours, gateways, and routes
- ICMP's purpose
- TCP's application-facing model and lifecycle
- Timeout, refusal, and reset
- Hypothesis-driven use of `ip` and `ping`

### Leave out

- Containers and Kubernetes
- Packet-capture analysis
- Kernel packet-path internals
- Packet-header memorization
- Detailed congestion-control algorithms
- A required throughput laboratory

## Starting references

- `man 8 ip`
- `man 8 ping`
- `man 7 ip`
- `man 7 tcp`
- [RFC 8200: Internet Protocol, Version 6](https://www.rfc-editor.org/rfc/rfc8200)
- [RFC 9293: Transmission Control Protocol](https://www.rfc-editor.org/rfc/rfc9293)

The group may choose IPv4 for its concrete examples while noting where the mental model differs for IPv6.

## Minimum preparation

- Lead the conceptual session and selected experiments.
- Share the references used.
