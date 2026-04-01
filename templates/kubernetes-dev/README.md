---
display_name: Kubernetes (Dev)
description: Full-featured Development Workspace with Cloud-Native tools and Gemini AI
icon: /icon/k8s.png
verified: true
tags: [kubernetes, dev, ai, gemini, vcluster]
---

# Kubernetes (Dev) 🚀

An advanced, batteries-included development workspace running on Kubernetes. This template is designed for software developers building cloud-native applications, featuring a full suite of modern development tools and AI assistance.

## ✨ Features

- **Built-in AI Assistant**: Comes pre-configured with the **Gemini CLI** for intelligent code generation, refactoring, and terminal assistance.
- **Virtual Clusters (vcluster)**: Option to provision a dedicated, isolated Kubernetes cluster directly alongside your workspace for safe testing.
- **Cloud-Native Tooling**: Includes essential Kubernetes tools (`kubectl`, `helm`, `k9s`, `devspace`).
- **Infrastructure as Code**: Ready-to-use with Terraform and Ansible.
- **Seamless Git Integration**: Automated cloning, automatic Git config injection, and commit signing via SSH/SOPS.
- **Code-Server IDP**: Includes an embedded VS Code interface (code-server) accessible directly from your browser.
- **Persistent Data**: Your `/home/coder` directory is persisted across workspace stops and starts.

## 🚀 Getting Started

1. Set your **Gemini API Key** during provisioning to enable the AI assistant.
2. Toggle **Enable Virtual Cluster** if you need a pristine Kubernetes environment for testing deployments.
3. Automatically clone your repositories and start coding in `code-server` or your local VS Code via SSH!
