---
display_name: Kubernetes (SRE)
description: Unified SRE workbench with Ansible, Flux, and K8s tools pre-installed.
icon: /icon/k8s.png
verified: true
tags: [kubernetes, sre, ansible, flux, gitops]
---

# Kubernetes (SRE)

A unified SRE workbench designed for Platform Engineering and DevOps teams.

## Features

- **Unified Toolset**: Comes pre-installed with the complete Cloud Native and Automation stack:
  - **Automation**: `ansible`
  - **GitOps**: `flux` CLI
  - **Kubernetes**: `kubectl`, `helm`, `k9s`
  - **Secrets**: `sops`, `age`
- **Multi-Repo Management**: Clone multiple infrastructure and playbook repositories at once via the `git_repos` parameter.
- **Optional Configuration**: Flexible injection of `ansible.cfg`, `inventory.ini`, `kubeconfig`, and SOPS keys.

## Deployment Strategy

This template is designed to serve as a "Control Plane" for your infrastructure.

1. **Provision**: Create a workspace.
2. **Connect**: Input your config repositories.
3. **Operate**: Run Ansible playbooks or Flux commands directly against your fleet.
