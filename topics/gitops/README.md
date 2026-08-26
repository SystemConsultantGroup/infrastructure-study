# GitOps

[Back to the curriculum](../../README.md)

## Profile

- **Audience:** Application developers
- **Leads:** 2
- **Duration:** 120 minutes

## Purpose

Learn how to establish an application repository, connect it to [SystemConsultantGroup/kubernetes](https://github.com/SystemConsultantGroup/kubernetes), and reason about the complete managed delivery lifecycle.

Participants should be able to onboard an application through the supported path without needing cluster or platform-operator access.

## Preparation brief

Prepare one managed application happy path. Follow production in full, then explain how testing and pull-request previews differ.

The session should connect two repositories and several systems without becoming an implementation walkthrough of every workflow, ApplicationSet, or Helm template. The philosophical focus is ownership: determine which repository is authoritative for source, build output, deployment intent, and runtime state.

## Starting material

Begin with these files in the Kubernetes repository:

- `applications/README.en.md`
- `applications/example/`
- `.github/workflows/README.en.md`
- `argocd/application-sets/README.en.md`
- `argocd/charts/application/README.en.md`

Use the documents to derive the workflow; do not copy their conclusions into the presentation without connecting them to the underlying GitOps model.

## Guiding vectors

### 1. Define the two-repository contract

Investigate:

- What belongs in an application repository?
- What belongs in the Kubernetes repository?
- Which repository initiates a delivery event?
- Which repository records deployment intent?
- Why is runtime state not written back as the primary source of truth?
- What authorization permits one repository to request a change in the other?

Draw the trust boundary before studying individual workflow steps.

### 2. Prepare a minimal application repository

Build or simulate a small repository and determine:

- Which application artifact must be buildable?
- Where must the Dockerfile and build context live?
- How is the shared workflow referenced and versioned?
- Which workflow events are relevant?
- Which permissions and credentials are required?
- Which data may safely be passed as build input?
- Which data must never be embedded in the workflow or image?

Prefer a disposable example over modifying an existing production application.

### 3. Register the managed application

Investigate the managed layout in the Kubernetes repository:

- Which files establish application and workload intent?
- Which information belongs in application metadata?
- Which information belongs in an instance lock?
- How is the initial production identity established?
- How are source and image identities connected?
- Which naming constraints cross repository, Argo CD, namespace, and Kubernetes boundaries?
- What validation protects the contract?

Mention the custom Kustomize layout only as an escape hatch and explain how a developer would know when further study is necessary.

### 4. Trace one production delivery

Follow one production change end to end:

1. An application source change occurs.
2. The application repository runs its delivery workflow.
3. An immutable build artifact and source identity are produced.
4. A cross-repository request is authenticated and validated.
5. Deployment intent changes in the Kubernetes repository.
6. Argo CD observes the new state.
7. Application generation and Helm rendering occur.
8. Kubernetes reconciles the resulting resources.

For every transition, identify the artifact, authority, identity, and possible failure.

The group should discover exact event mappings and workflow behavior from repository documentation rather than receiving them as curriculum facts.

### 5. Compare testing and preview behavior

After the production flow is clear, investigate:

- What event identifies a testing deployment?
- What event identifies a preview?
- How is preview identity derived?
- What happens when a preview is updated or closed?
- Which configuration or services can a preview share?
- Which security assumptions differ from production?

Present only the differences; do not repeat the complete production trace.

### 6. Connect to generation at a high level

Use the understanding from Kubernetes Part 2 to determine:

- How an application declaration becomes an Argo CD Application.
- Where shared values and templates enter the flow.
- Which resources are generated for the example workload.
- How generated identity remains connected to application identity.

Do not perform a line-by-line walkthrough of ApplicationSet or chart templates.

### 7. Evaluate the philosophy

Conclude with:

- Why immutable source and image identities matter.
- Why the workflow changes Git rather than the cluster.
- Why application developers do not need cluster credentials.
- Which controls constrain untrusted application events.
- What audit trail exists across the two repositories.
- Which failure modes the design accepts in exchange for those properties.

## Scope boundaries

### Keep

- One managed application onboarding
- Application repository setup
- Shared workflow integration
- Cross-repository authorization and trust
- Immutable source and image identity
- Initial registration in the Kubernetes repository
- Full production lifecycle
- Testing and preview differences
- ApplicationSet and Helm generation at overview level

### Leave out

- Detailed custom Kustomize onboarding
- Reusable workflow implementation internals
- Shared chart template internals
- Argo CD platform administration
- Platform recovery
- Production credentials or live production modifications

## Minimum preparation

- Lead the managed onboarding and lifecycle session.
- Share the references used.

A disposable example repository or convincing simulation is useful but not mandatory.
