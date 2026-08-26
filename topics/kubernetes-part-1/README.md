# Kubernetes (Part 1)

[Back to the curriculum](../../README.md)

## Profile

- **Audience:** Application developers
- **Leads:** 3
- **Duration:** 120 minutes

## Purpose

Understand Kubernetes as a declarative system of APIs and reconciling controllers, then use resource identity and ownership to explain how independently operating controllers compose a workload.

Participants should be able to start with one application declaration and derive the identities and relationships of the resources created to maintain it.

## Preparation brief

Begin with philosophy and control systems, not a catalogue of resource types. Use one minimally containerized application throughout the session.

Resource definitions are a central subject: investigate how type, name, UID, namespace, labels, selectors, and owner references establish identity and relationships. Do not reduce the topic to writing YAML.

## Guiding vectors

### 1. Establish the Kubernetes philosophy

Investigate:

- Which operational problems led to Kubernetes's design?
- What is the difference between issuing an action and declaring desired state?
- What roles do the API server and controllers play in that model?
- How are desired and observed state represented?
- What does eventual convergence imply during normal operation and failure?
- Why are controllers designed to be independently reconciling and retrying?
- What responsibilities remain with the application developer?

Relate these questions to the imperative/declarative distinction introduced in the first session.

### 2. Introduce the deployment artifact

Build one minimal container image and investigate:

- What exactly is being handed to Kubernetes?
- Which runtime behavior is inside the artifact, and which is declared to the platform?
- Which properties should remain stable across environments?
- What must the application expose so that the platform can manage it correctly?

Keep Dockerfile optimization and container-runtime internals outside the core scope.

### 3. Read a Kubernetes resource definition

Use representative resources to investigate:

- `apiVersion`, `kind`, `metadata`, `spec`, and `status`
- API group, version, and kind as resource type identity
- Namespaced and cluster-scoped resources
- Schema validation and defaulting
- User-declared intent versus system-reported observation
- Which fields are stable identity and which are mutable configuration

Ask what a client, API server, and controller each need from the definition.

### 4. Derive object identity

Build a coherent identity model around:

- Resource type, namespace, and name
- Generated names
- UIDs and object reincarnation
- Labels as descriptive identity
- Selectors as dynamic association
- Owner references as lifecycle and controller relationships
- Controller ownership and garbage collection

Explore why names alone are insufficient and why labels alone do not express ownership.

### 5. Follow the controller lineage

Starting from one Deployment, derive and inspect:

- The Deployment's identity and desired state
- The ReplicaSet selected or created to realize that state
- The Pods owned by the ReplicaSet
- The labels and selectors that connect the chain
- The Service and the Pods it selects
- Which names or hashes change during a rollout
- Which relationships survive deletion and recreation

The group should be able to explain every resulting resource name, UID, owner, label, and selector without treating them as arbitrary YAML.

### 6. Explore the application contract

Use the same workload to investigate:

- Configuration and secret references
- Resource requests and limits
- Readiness
- Graceful termination
- Replica changes and rollout

Ask how each declaration affects controller decisions and what behavior Kubernetes expects from the application.

### 7. Observe reconciliation

Prepare a small set of changes or failures:

- Delete a managed Pod.
- Change desired replica count.
- Change the Pod template.
- Make readiness fail.
- Recreate an object with the same name.

Before observing the result, require a prediction based on identity, ownership, and controller responsibility.

## Scope boundaries

### Keep

- Declarative APIs and control loops
- Desired state, observed state, and convergence
- Minimal image build
- Pod, Deployment, ReplicaSet, and Service relationships
- Resource definitions and API identity
- Names, UIDs, labels, selectors, and owner references
- Configuration, resources, readiness, and shutdown as application contracts
- Reconciliation experiments

### Leave out

- Comparison with virtual machines
- Container runtime internals
- Detailed Dockerfile optimization
- Broad surveys of every workload type
- Storage and scheduling deep dives
- Extensive YAML syntax instruction
- Platform-specific generated naming; that appears in Part 2 and GitOps

## Starting references

- [Kubernetes Objects](https://kubernetes.io/docs/concepts/overview/working-with-objects/)
- [Object Names and IDs](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/)
- [Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
- [Owners and Dependents](https://kubernetes.io/docs/concepts/overview/working-with-objects/owners-dependents/)
- [Controllers](https://kubernetes.io/docs/concepts/architecture/controller/)
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)

## Minimum preparation

- Lead the philosophical and resource-identity investigation.
- Share the references used.
