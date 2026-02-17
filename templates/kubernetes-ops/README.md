---
display_name: Kubernetes (Ops)
description: Specialized minimal workspace for Kubernetes cluster management and GitOps.
icon: /icon/k8s.png
verified: true
tags: [kubernetes, ops, gitops]
---

# Kubernetes (Ops)

Standard development workspace on Kubernetes, pre-configured with Git integration.

## Features

- **Persisted Home Directory**: Files in `/home/coder` are saved between restarts.
- **Git Integration**: Comes with `git-config` and `git-commit-signing` modules for seamless version control.
- **Pre-installed Tools**: Includes standard development utilities.

## Prerequisites

- **Cluster**: Requires an existing Kubernetes cluster.
- **Authentication**: Uses `~/.kube/config` or ServiceAccount.

## Architecture

Provisions a Kubernetes Pod with a PersistentVolumeClaim. Ideal for daily development tasks.
