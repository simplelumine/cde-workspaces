---
display_name: Kubernetes (SRE)
description: Unified SRE/DevOps workbench with GitOps tools, DB administration, and Gemini AI.
icon: /icon/k8s.png
verified: true
tags: [kubernetes, sre, ansible, flux, gitops, gemini]
---

# Kubernetes (SRE) 🛠️

A unified Platform Engineering and SRE workbench designed for cluster administrators, DevOps engineers, and infrastructure operators.

## ✨ Features

- **GitOps & Automation**: Pre-installed with `flux` CLI and `ansible` for managing fleet deployments and playbooks.
- **Database Administration**: Features `cnpg` (CloudNativePG) plugin for advanced PostgreSQL cluster management.
- **Secrets Management**: Deep integration with `sops` and `age` for secure secret decryption and encryption on the fly.
- **Built-in AI Assistant**: Comes pre-configured with the **Gemini CLI** to help write playbooks, explain manifests, and debug complex infrastructure issues.
- **Virtual Clusters (vcluster)**: Instantly launch a sandboxed Kubernetes cluster to test GitOps operators and helm charts without breaking production.
- **Complete K8s Suite**: Includes `kubectl`, `helm`, `k9s`, and Terraform out-of-the-box.
- **Multi-Repo Git Integration**: Clone multiple infrastructure repositories simultaneously, fully configured with Git signing.

## 🚦 Deployment Strategy

This workspace functions as your dedicated "Control Plane":

1. **Deploy**: Provision your SRE workspace, injecting your AWS/GCP credentials and Gemini API Key.
2. **Setup**: Provide your SOPS Age key and SSH keys to unlock your infrastructure repos.
3. **Operate**: Use K9s, Flux, and Ansible to safely manage your clusters with the help of Gemini AI.
