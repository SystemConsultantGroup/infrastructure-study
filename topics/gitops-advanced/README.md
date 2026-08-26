# GitOps (Advanced)

[Back to the curriculum](../../README.md)

## Profile

- **Audience:** Platform engineers
- **Leads:** 3
- **Duration:** 120 minutes

## Purpose

Understand the SCG Kubernetes repository as the platform's source of truth and reason safely about its reconciliation hierarchy, trust boundaries, supported `k` operations, and representative incidents.

The goal is an operating model, not an inventory of every platform component or a complete disaster-recovery manual.

## Preparation brief

Organize the session around the boundary between declarative reconciliation and the imperative operations that remain necessary for bootstrap, change, and recovery.

Use the repository and `k --help` as primary evidence. Do not execute mutating or destructive commands against the production cluster while preparing or presenting this topic.

## Starting material

Begin with:

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

Map these by responsibility and trust boundary rather than presenting a directory tour.

## Guiding vectors

### 1. Map the sources of truth

Investigate:

- Which desired state belongs to Git?
- Which state is derived during rendering or reconciliation?
- Which state exists only in Talos, Kubernetes, Argo CD, or an external system?
- Which generated artifacts must not become independently edited sources of truth?
- How does an operator determine which declaration should be changed?
- What happens when two apparent sources disagree?

Create a hierarchy that connects cluster state, platform state, and application state.

### 2. Trace root reconciliation

Starting at the root, determine:

- How does Argo CD discover the rest of the desired state?
- Which resources generate or own other Applications?
- How are application and platform concerns separated?
- Where are authorization boundaries enforced?
- How do shared application contracts enter the hierarchy?
- Which dependencies cannot be solved by arbitrary application order?
- What happens when a controller or CRD needed for reconciliation is absent?

Choose representative branches of the hierarchy rather than documenting every platform component.

### 3. Investigate validation and change safety

Research:

- Which checks can run before merge?
- Which invalid states are caught only during rendering or admission?
- What does formatting contribute beyond style?
- Which naming, identity, and repository invariants are validated?
- What review assumptions remain outside automation?
- What is the operational consequence of merging to the tracked branch?

Run safe local checks where practical and distinguish repository validation from cluster-side validation.

### 4. Map secrets and trust boundaries

Investigate at a system level:

- Which secret material may exist in Git and in what form?
- Which keys or identities can decrypt or materialize it?
- How are application runtime values separated from repository metadata?
- Which systems need access to plaintext?
- How are recipient and access changes reviewed?
- What failures occur when a secret controller or backing service is unavailable?

Focus on trust relationships and failure behavior, not on exposing actual values.

### 5. Understand why `k` exists

Read the command interface and ask:

- Which operational complexities is it hiding or standardizing?
- Which repository state does each command consume?
- Which commands merely observe or validate?
- Which commands mutate a machine, cluster, secret store, or repository?
- Which commands are destructive or recovery-oriented?
- Which operations cannot be achieved by ordinary Argo CD reconciliation?
- After an imperative operation, how does the system return to declared state?

Classify representative commands as:

1. Observational
2. Validating
3. Mutating
4. Destructive
5. Recovery-oriented

Do not attempt a complete command reference.

### 6. Examine the bootstrap boundary

Investigate the apparent circular dependencies in a declarative platform:

- What must exist before Argo CD can reconcile anything?
- What must exist before secrets can be materialized?
- What must exist before platform controllers can process their resources?
- Which steps are necessarily imperative?
- How is ownership handed back to reconciliation?
- Which state is required to reproduce the cluster?

Represent bootstrap as dependencies and state transitions, not merely a command sequence.

### 7. Analyze two incidents

Choose two representative incidents, such as:

- A merged platform change cannot converge.
- A required secret cannot be materialized.
- A node must be replaced.
- An upgrade partially succeeds.
- Git and cluster state disagree after manual intervention.

For each incident, determine:

- The authoritative desired state
- Evidence to collect
- Safe observational steps
- Whether reconciliation should be allowed, paused, or repaired
- Whether `k` is relevant and at what risk level
- How to restore a legible desired state
- What confirms recovery

The goal is disciplined reasoning, not a production-ready runbook.

## Scope boundaries

### Keep

- Root reconciliation hierarchy
- Application and platform responsibility boundaries
- Validation and merge consequences
- Secrets trust model
- Purpose and risk classification of `k`
- Declarative versus necessary imperative operations
- Bootstrap dependencies
- Two incident analyses

### Leave out

- An inventory of every platform component
- Argo CD UI or administration tutorial
- A complete `k` command catalogue
- A complete disaster-recovery runbook
- Live destructive operations
- Production secret values
- Detailed application onboarding already covered by GitOps

## Minimum preparation

- Lead the operating-model and incident discussion.
- Share the references used.

Any command demonstrations must be read-only, local, or performed in a disposable environment.
