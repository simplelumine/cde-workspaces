# CDE Workspaces

Managed workspace definitions for [Coder](https://coder.com), enabling consistent, reproducible, and scalable cloud development environments across diverse infrastructure providers.

This repository contains a collection of advanced Kubernetes-based workspace templates infused with AI capabilities.

## 📦 Templates

### [Kubernetes (Dev)](./templates/kubernetes-dev)
A full-featured development environment tailored for software engineers building cloud-native applications.
- **Cloud-Native**: `vcluster`, `devspace`, `kubectl`, `helm`.
- **AI-Powered**: Built-in **Gemini CLI** for intelligent coding assistance.
- **Git Integration**: Automated cloning, config injection, and commit signing.
- **Persistence**: Persistent home directory across restarts.

### [Kubernetes (SRE)](./templates/kubernetes-sre)
A unified DevOps/Platform Engineering workbench built for infrastructure operators.
- **Everything in Dev**: Includes Gemini AI, vcluster, and core Kubernetes tools.
- **GitOps & Automation**: Pre-installed with `flux`, `ansible`, and `terraform`.
- **Database & Secrets**: Features `cnpg` (CloudNativePG) and `sops` / `age` encryption workflows.
- **Multi-Repo Management**: Designed to orchestrate multiple infrastructure repositories seamlessly.

## 🚀 Usage

1. **Add Template to Coder**:
   - Run: `coder templates push` within the desired template directory, or
   - Use the Coder UI: Create Template -> Clone from Git -> Use this repository URL.
   
2. **Create a Workspace**:
   - Supply your Gemini API key and specific parameters (like vcluster toggle, Git URLs).
   - Start coding!
