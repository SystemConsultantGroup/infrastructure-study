# Talos (Advanced)

[Back to the curriculum](../../README.md)

## Profile

- **Audience:** Platform engineers
- **Leads:** 2
- **Duration:** 120 minutes

## Purpose

Understand the design philosophy and lifecycle of a Talos-managed Kubernetes node, then validate that model by observing a disposable QEMU node through `talosctl`.

This is a theory-led session with a bounded laboratory, not an operations runbook.

## Preparation brief

Derive Talos's operating model from the problems it is designed to solve. Follow one node through configuration, startup, observation, reboot, and shutdown at a conceptual level.

The QEMU laboratory should make the model tangible. It should not become a full Kubernetes bootstrap, upgrade, or recovery exercise. The repository's `k` interface belongs to GitOps (Advanced), not this session.

## Guiding vectors

### 1. Identify the problem and design constraints

Research:

- Which sources of node drift or operational uncertainty is Talos addressing?
- What assumptions does it make about the role of a Kubernetes node?
- How does its access model differ from conventional server administration?
- Which administrative capabilities are intentionally absent or constrained?
- What security and operability consequences follow?

Present the trade-offs rather than describing the design only as a list of features.

### 2. Build the machine-state model

Investigate:

- How is desired machine state represented?
- Which configuration is machine-specific, cluster-wide, or derived?
- How does a node receive and validate configuration?
- Which changes can occur while running, and which require a lifecycle transition?
- How are secrets and trust established for machine API access?
- How should an operator distinguish declared configuration from observed state?

Use one representative configuration only after the conceptual model is clear.

### 3. Trace the node lifecycle

Construct a high-level lifecycle covering:

- Initial boot
- Configuration availability
- Service startup
- Joining or contributing to a Kubernetes cluster
- Normal observation
- Configuration change
- Reboot or shutdown
- Maintenance and recovery states

Ask what evidence is available at each stage and which control interface remains usable when Kubernetes itself is unavailable.

Keep detailed etcd internals and production recovery procedures outside the session.

### 4. Prepare the QEMU laboratory

Use the current official Talos QEMU guidance to create a disposable environment. The laboratory should demonstrate only enough to validate the theory:

1. Boot a Talos node or minimal local environment under QEMU.
2. Establish `talosctl` access.
3. Inspect machine state and services.
4. Inspect logs and effective configuration.
5. Relate observed state to the lifecycle model.
6. Reboot or stop the node and observe transitions.
7. Clean up the environment.

During preparation, identify:

- Host architecture and acceleration requirements
- Required privileges and networking support
- Differences between Linux and macOS QEMU hosts
- A fallback plan if virtualization is unavailable during the session

Do not use production credentials or configuration.

### 5. Evaluate the operating model

Conclude by asking:

- Which classes of operational error become harder?
- Which familiar debugging techniques become unavailable?
- What new evidence or workflows replace them?
- Which failures require repair, reconfiguration, or replacement?
- How does the model support or challenge declarative infrastructure principles?

## Scope boundaries

### Keep

- Talos design goals and trade-offs
- Machine configuration as desired state
- Node boot and lifecycle concepts
- API access and observation
- Maintenance and recovery as conceptual states
- A disposable `talosctl`/QEMU observation lab

### Leave out

- The repository's `k` commands
- A full SCG repository walkthrough
- A complete Kubernetes cluster lab
- Detailed etcd internals
- Talos or Kubernetes upgrade procedures
- Destructive recovery exercises
- Hardware-specific production procedures

## Starting references

- [Talos Linux documentation](https://docs.siderolabs.com/talos/)
- [Talos QEMU platform guide](https://docs.siderolabs.com/talos/v1.13/platform-specific-installations/local-platforms/qemu)
- [Talos support matrix](https://docs.siderolabs.com/talos/v1.13/getting-started/support-matrix)
- Representative `state.yaml` and `patches/` files in [SystemConsultantGroup/kubernetes](https://github.com/SystemConsultantGroup/kubernetes), used only after establishing the generic model

Use documentation matching the Talos version selected for the lab rather than assuming the linked version remains current.

## Minimum preparation

- Lead the design and lifecycle discussion.
- Prepare and validate the disposable QEMU observation lab.
- Share the references used.
