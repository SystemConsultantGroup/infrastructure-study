# Introduction

[Back to the curriculum](../../README.md)

## Profile

- **Audience:** Everyone
- **Leads:** 2
- **Duration:** 120 minutes

## Purpose

Establish a common Linux/Nix study environment and build the conceptual foundation for declarative, reproducible infrastructure.

By the end of the session, participants should be able to enter the provided environment from a fresh Linux setup and explain what the environment does—and does not—make reproducible.

## Preparation brief

Prepare a lean setup session. Linux setup is part of the study, but general Linux administration and Nix implementation internals are not.

The practical thread should run from a fresh environment to a successful development shell. Use that journey to motivate the difference between remembered setup commands and declared environment state.

## Guiding vectors

### 1. Establish the Linux baseline

Investigate and decide:

- What constitutes a sufficient Linux environment for the remaining sessions?
- Which shell and filesystem concepts are essential to follow later demonstrations?
- What assumptions does the study make about architecture, privileges, and network access?
- Which setup differences between native Linux, a VM, and other host environments matter?

Keep the baseline minimal. Introduce commands only when they are necessary for using the repository or diagnosing setup failures.

### 2. Compare setup models

Construct a small comparison between imperative and declarative setup:

- How would the required tools be installed and versioned manually?
- Which parts of that process depend on memory, ordering, or machine history?
- What can be expressed as desired state instead?
- What kinds of reproducibility are possible, and where do host-level differences remain?

The point is to establish a mental model that will reappear in Kubernetes, Talos, and GitOps.

### 3. Introduce Determinate Nix

Research enough Nix to explain:

- Why the study uses Nix for its tool environment.
- What installing Determinate Nix changes on the host.
- What a Flake contributes to environment discovery and version pinning.
- What happens conceptually when a participant enters the development shell.

Do not turn this into a Nix language lesson.

### 4. Exercise the provided environment

Using the study Flake, prepare a fresh-environment walkthrough:

1. Set up Linux.
2. Install Determinate Nix.
3. Clone the study repository.
4. Enter the development shell.
5. Verify representative tools.
6. Leave and re-enter the shell.
7. Identify which state belongs to the host and which belongs to the repository.

Include at least one setup failure and explain how to investigate it.

## Scope boundaries

### Keep

- Linux environment setup
- Essential shell and filesystem survival skills
- Imperative versus declarative setup
- Determinate Nix installation
- Using the provided Flake
- A fresh environment to development shell demonstration

### Leave out

- Nix language instruction
- Derivations and Nix store internals
- Flake authoring
- General Linux system administration
- A broad command-line tutorial

## Starting references

- [Determinate Nix documentation](https://docs.determinate.systems/)
- [NixOS Wiki: Flakes](https://wiki.nixos.org/wiki/Flakes)
- The study repository's `flake.nix` and `flake.lock`

## Minimum preparation

- Lead the setup and philosophy discussion.
- Share the references used.

Diagrams, setup notes, and troubleshooting exercises are encouraged but optional.
