# Kubernetes (Part 2)

[Back to the curriculum](../../README.md)

## Profile

- **Audience:** Application developers
- **Leads:** 3
- **Duration:** 120 minutes

## Purpose

Understand how Helm, Argo CD, and Gateway API extend Kubernetes's declarative model across packaging, Git reconciliation, and application routing.

Participants should be able to follow one application input through all three systems and identify which system owns each transformation or decision.

## Preparation brief

Assign a primary investigator to Helm, Argo CD, and Gateway API, but prepare one shared narrative rather than three independent presentations.

For every system, answer the same questions:

- What problem does it solve?
- What mental model does it introduce?
- What input and state does it own?
- What output does it produce or reconcile?
- Where does its responsibility end?

## Guiding vectors

### 1. Choose one application thread

Select a small application declaration from the SCG Kubernetes repository. Establish the inputs that an application developer controls without first revealing every generated resource.

The final trace should connect:

1. Application input
2. Helm rendering
3. Argo CD reconciliation
4. Kubernetes resources
5. Gateway API routing
6. A backend Service

Use the trace to expose boundaries between transformation, reconciliation, and runtime behavior.

### 2. Investigate Helm's role

Research:

- Which repetition or variability is Helm intended to manage?
- What is the relationship between a chart, values, templates, and rendered manifests?
- Which validation can happen before resources reach Kubernetes?
- Does Helm continuously maintain the resources it renders?
- What makes a shared chart a useful application contract?
- At what point can abstraction hide too much?

Prepare one small rendering example. Avoid a template-language tutorial and do not explore helper functions unless the shared trace requires them.

### 3. Investigate Argo CD's role

Research:

- How does Argo CD extend the controller and reconciliation model from Part 1?
- What does an Argo CD Application identify?
- Which desired and observed states are compared?
- How should synchronization, health, and drift be distinguished?
- What happens when generated manifests are invalid or cannot converge?
- Which responsibilities belong to application developers and which belong to platform operators?

Keep Argo CD administration, UI operation, Projects, and advanced synchronization behavior for GitOps (Advanced).

### 4. Investigate Gateway API's role

Research:

- Which limitations motivated Gateway API?
- How does its resource model divide infrastructure and application ownership?
- How are listeners, routes, and backends related?
- How is a route allowed to attach?
- How are host and path decisions expressed?
- Where can TLS terminate?
- Which controller turns the API declarations into runtime behavior?

Use only the routing features required by the selected application. Advanced filters and cross-namespace designs are optional.

### 5. Integrate the systems

For each transition in the shared trace, determine:

- Is this step rendering, reconciliation, admission, controller action, or request processing?
- What artifact or API resource crosses the boundary?
- Is the step one-time or continuous?
- What identity connects its input to its output?
- Where would a failure be visible?
- Which system should be investigated first?

The result should make clear that these systems complement rather than replace the Kubernetes control model.

## Scope boundaries

### Keep

- One integrated application lifecycle
- Helm chart, values, template, and rendering concepts
- Argo CD Application and reconciliation concepts
- Gateway API ownership and basic HTTP routing model
- Generated Kubernetes resources and identity transitions
- Responsibility and failure boundaries

### Leave out

- Detailed Helm template syntax
- Argo CD administration
- Argo CD Projects and platform reconciliation hierarchy
- Advanced Gateway API filters and matching
- Independent full demonstrations for all three systems
- Application-repository onboarding; that belongs to GitOps

## Starting references

- [Helm: Charts](https://helm.sh/docs/topics/charts/)
- [Helm: Chart Template Guide](https://helm.sh/docs/chart_template_guide/)
- [Argo CD Core Concepts](https://argo-cd.readthedocs.io/en/stable/core_concepts/)
- [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/)
- [SystemConsultantGroup/kubernetes](https://github.com/SystemConsultantGroup/kubernetes), especially the application example, shared application chart, ApplicationSets, and relevant routes

Repository paths are starting points for investigation, not conclusions about the generated flow.

## Minimum preparation

- Lead one integrated session across the three systems.
- Share the references used.
