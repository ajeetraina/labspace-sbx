# Labspace for Docker Sandboxes (sbx)

An interactive lab for learning Docker Sandboxes — the microVM-based agent environment built by Docker.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [ttyd](https://github.com/tsl0922/ttyd): `brew install ttyd`
- [sbx](https://github.com/docker/sbx-releases): `brew install docker/tap/sbx`

## Quick Start

```bash
git clone https://github.com/ajeetraina/labspace-sbx
cd labspace-sbx
bash start.sh
```

Open http://localhost:3030

- **Left panel** → Lab instructions
- **Right panel** → Your Mac terminal with `sbx` ready to use

## What you'll learn

- What Docker Sandboxes (sbx) are and why they exist
- How sbx uses microVMs for agent isolation
- Running AI agents safely inside sbx sandboxes
- Sandbox lifecycle: create, exec, list, stop
