---
display_name: Cloud-Native Workspace
description: Unified Cloud-Native development workbench with dynamic toolchains, vcluster isolation, and Gemini AI.
icon: /icon/k8s.png
tags: [cloud-native, kubernetes, vcluster, terraform, go, python, nodejs, gemini]
---

# Cloud-Native Workspace ☁️

A highly flexible and unified cloud-native environment dynamically adapting to your roles—from application development to privileged infrastructure operations.

## ✨ Features

- **Multi-Mode Architecture**: Choose between `Standard` mode for general coding, `Sandbox` for isolated vcluster testing, or `Privileged` for full SRE toolchains (Flux, CloudNativePG).
- **Dynamic Toolchains**: Instantly provision your required language environments at startup, including **Go, Python, and Node.js**.
- **Secure & Integrated**: Seamlessly integrated with Git/GitHub, automatic SSH key provisioning, Git object signing, and SOPS for secret management.
- **Infrastructure as Code**: Comes equipped with a robust toolkit including `terraform`, `ansible`, and Kubernetes operational essentials (`kubectl`, `helm`, `k9s`).
- **Built-in AI Assistant**: Deeply integrated with the **Gemini CLI**, assisting you with task automation, coding, and debugging directly in the terminal (with optional YOLO automation mode).

## 🚦 Deployment Strategy

1. **Resource Setup**: Define your computational footprint by selecting the `Workspace Resource Tier` and `Workspace Storage Tier`.
2. **Select Mode & Stack**: Toggle between Standard/Sandbox/Privileged operational modes and check the dev toolchains you need today.
3. **Develop & Operate**: Use your dynamically configured stack to develop microservices, or safely test Kubernetes operators in your isolated vcluster without affecting production.
