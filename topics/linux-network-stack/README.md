# Linux Network Stack (Advanced)

[Back to the curriculum](../../README.md)

## Profile

- **Audience:** Platform engineers
- **Leads:** 3
- **Duration:** 120 minutes

## Purpose

Trace the lifecycle of a TCP write and read through the Linux kernel, then use that foundation to investigate one representative connection in a Cilium-backed Kubernetes cluster.

The objective is not to memorize a universal packet-path diagram. Participants should learn how to derive a path from Linux mechanisms, deployment choices, documentation, and observations.

## Preparation brief

Build the session around a byte written by one process and read by another. Establish the ordinary Linux path before introducing namespaces, Kubernetes, or Cilium.

This is a kernel-focused session. Prefer one coherent deep trace over a catalogue of every possible Kubernetes traffic path.

## Guiding vectors

### 1. Define the endpoints of the trace

Choose a concrete TCP client and server and establish:

- Which userspace calls begin and end the journey?
- What does a successful `write()` mean?
- What does a successful `read()` mean?
- Which state exists in userspace, and which exists in the kernel?
- At what points can data be copied, queued, segmented, delayed, or dropped?

Be explicit about the boundary between application bytes, TCP segments, IP packets, and link-layer frames.

### 2. Follow the transmit path

Research the path from the sending process toward the network device. Locate the responsibilities of:

- The syscall and socket layers
- Socket send buffers
- TCP state and segmentation
- IP routing and output processing
- Kernel packet representations
- Queueing disciplines
- Device and driver queues
- Offload features
- The physical or virtual device boundary

The group should decide which details are essential to preserve a correct mental model and which can be abstracted.

### 3. Follow the receive path

Reverse the perspective from incoming data to the receiving process:

- How does the kernel learn that work is available?
- Where do interrupts, polling, and receive queues enter the model?
- How is the relevant protocol and socket selected?
- Where are ordering and acknowledgement handled?
- How does a blocked process become runnable?
- When do bytes become available to `read()`?

Connect the transmit and receive paths into one lifecycle rather than presenting two unrelated diagrams.

### 4. Introduce namespaces and virtual devices

After the ordinary path is established, investigate:

- What changes when the process runs in a network namespace?
- Which networking state belongs to the namespace?
- How do virtual devices connect namespace and host paths?
- Which parts of TCP remain unchanged?
- Which additional routing or forwarding decisions appear?

Build a small namespace experiment if it helps validate the model, but do not let environment setup consume the session.

### 5. Investigate Cilium's integration

Use primary Cilium and Linux sources to determine:

- At which Linux attachment points can Cilium influence the connection?
- Which state may be held in eBPF maps?
- How can service selection and policy enforcement be represented?
- Which traditional Linux mechanisms may still participate?
- Which details depend on cluster configuration?

Do not assume the answer from a generic Cilium diagram. Clearly identify what would need to be inspected or observed to determine the path in a particular cluster.

### 6. Derive one Kubernetes path

Select one representative TCP connection in a Cilium-backed Kubernetes environment and derive its lifecycle:

- Identify the source and destination processes.
- Enumerate namespace and device transitions.
- Identify routing, service-selection, and policy decision points.
- Determine which parts follow the ordinary Linux path.
- Determine which parts are introduced or altered by the Kubernetes datapath.
- Separate verified facts, observations, and inferences.

The core session should not attempt same-node, cross-node, and external Gateway paths all at once.

### 7. Make the model observable

Select only the tools that help validate specific stages. Candidates include:

- `ss`
- `tcpdump`
- `bpftool`
- Cilium observability commands
- Kernel tracing facilities

For every observation, explain what layer it exposes and what remains hidden.

## Scope boundaries

### Keep

- Syscalls and socket buffers
- TCP send and receive lifecycle
- Kernel packet representation
- Routing and queueing
- NAPI, device queues, and relevant offload concepts
- Network namespaces and virtual devices
- eBPF attachment points
- One derived Cilium-backed Kubernetes connection

### Leave out

- A survey of every Cilium deployment mode
- An exhaustive same-node/cross-node comparison
- Gateway and Envoy traffic paths
- Detailed congestion-control algorithm comparisons
- Netfilter history
- A generic Cilium configuration walkthrough

## Starting references

- [Linux kernel networking documentation](https://docs.kernel.org/networking/)
- [Linux kernel NAPI documentation](https://docs.kernel.org/networking/napi.html)
- [Linux kernel scaling documentation](https://docs.kernel.org/networking/scaling.html)
- [Cilium eBPF datapath documentation](https://docs.cilium.io/en/stable/network/ebpf/)
- [Cilium: Life of a Packet](https://docs.cilium.io/en/latest/network/ebpf/lifeofapacket/)
- [BPF documentation](https://docs.kernel.org/bpf/)

Treat diagrams in secondary sources as hypotheses to verify against current primary documentation.

## Minimum preparation

- Lead the kernel lifecycle and Kubernetes mapping.
- Share the references used.

A diagram or trace is strongly useful for this topic, but the group chooses its teaching artifacts.
