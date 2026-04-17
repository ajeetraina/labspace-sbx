# Labspace for Docker Sandboxes (sbx)

An interactive lab for learning Docker Sandboxes — the microVM-based agent environment built by Docker.

<img width="1850" height="979" alt="image" src="https://github.com/user-attachments/assets/86bab658-04de-43d4-8f68-478a1a3f0da8" />


## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [ttyd](https://github.com/tsl0922/ttyd): `brew install ttyd`
- [sbx](https://github.com/docker/sbx-releases): `brew install docker/tap/sbx`

## Quick Start

```bash
git clone https://github.com/ajeetraina/labspace-sbx
cd labspace-sbx
bash start-labspace.sh
```

Open http://localhost:3030

- **Left panel** → Lab instructions
- **Right panel** → Your Mac terminal with `sbx` ready to use

## What you'll learn

- **Why microVM isolation matters** for AI agents and how sbx's boundary differs from a container
- **The four layers of agent governance:** structural isolation, credential proxy injection, network policy enforcement, and audit logging
- **Running your first sandbox** and proving an agent cannot escape the VM — with real commands against real file paths
- **Reviewing agent changes** with Git worktrees before any code touches your working tree
- **Injecting secrets** into agents without ever exposing them to the VM
- **Enforcing network policy** at the proxy layer — and watching allowed and blocked connections in a live audit log
- **Branch mode and parallel agents** — running multiple autonomous agents on the same repo simultaneously, each governed by the same policy
- **Air-gapped agent workflows** — running open-source models locally with Docker Model Runner, zero cloud dependency
- **The enterprise architecture:** what it takes to govern 30,000 concurrent agent sessions across a workforce
