---
display_name: Kubernetes (Dev)
description: Dev environment with Git configuration and essential tools
icon: /icon/k8s.png
verified: true
tags: [kubernetes, git, dev]
---

# Kubernetes (Dev)

Dev workspace on Kubernetes, pre-configured with Git integration.

## Features

- **Persisted Home Directory**: Files in `/home/coder` are saved between restarts.
- **Git Integration**: Comes with `git-config` and `git-commit-signing` modules for seamless version control.
- **Pre-installed Tools**: Includes dev utilities.

## Prerequisites

- **Cluster**: Requires an existing Kubernetes cluster.
- **Authentication**: Uses `~/.kube/config` or ServiceAccount.

## Architecture

Provisions a Kubernetes Pod with a PersistentVolumeClaim. Ideal for daily development tasks.
