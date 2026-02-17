# CDE Workspaces

Managed workspace definitions for [Coder](https://coder.com), enabling consistent, reproducible, and scalable cloud development environments across diverse infrastructure providers.

This repository contains a collection of workspace templates:

## Templates

### [Kubernetes (Standard)](./templates/kubernetes-standard)
Standard development environment on Kubernetes.
- **Base image**: Ubuntu-based with essential dev tools.
- **Git Integration**: Automated cloning and signing.
- **Persistence**: Persistent home directory.

### [Kubernetes (Gemini)](./templates/kubernetes-gemini)
AI-enhanced workspace on Kubernetes.
- **Everything from Standard**: Includes all Git and persistence features.
- **Gemini CLI**: Built-in Google Gemini AI assistant.
- **Seamless Integration**: Pre-configured environment variables.

## Usage

1.  **Create a Template**:
    -   Run: `coder templates create`
    -   Select "Clone from Git" and use this repository URL.
    -   Choose the subdirectory for your desired template.

2.  **Create a Workspace**:
    -   Fill in parameters.
    -   Start coding!
