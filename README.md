# labspace-sbx

**Running AI Agents Safely with Docker Sandboxes** — an interactive, browser-based lab that teaches structural AI governance hands-on.

## What you'll learn

- Why microVM isolation is fundamentally different from a permission dialog
- How to prove an agent cannot access host credentials (you'll try yourself)
- How secret injection works without exposing keys to the agent
- How to configure and observe network policy enforcement in real time
- Branch mode: getting clean agent diffs for review before merge
- Parallel agents: two agents, one sandbox, zero conflicts

## Requirements

| Platform | Status |
|---|---|
| macOS Apple Silicon (M1/M2/M3/M4) | ✅ Fully supported |
| Linux x86_64 with KVM access | ✅ Supported |
| macOS Intel | ❌ Not supported (no microVM) |
| Windows 11 x86_64 | ⚠️ Supported, some exercises differ |

**Pre-requisites:**
- `sbx` installed: `brew install docker/tap/sbx`
- `sbx login` complete (Docker OAuth)
- OpenAI API key stored: `echo "$OPENAI_API_KEY" | sbx secret set -g openai`

## Launch the Labspace

```bash
# With Docker Desktop
docker compose -f oci://ajeetraina/labspace-sbx up -d

# Then open
open http://localhost:3030
```

## Local development

```bash
git clone https://github.com/ajeetraina/labspace-sbx
cd labspace-sbx

# Mac/Linux
CONTENT_PATH=$PWD docker compose up --watch

# Windows (PowerShell)
$Env:CONTENT_PATH = (Get-Location).Path; docker compose up --watch
```

Open http://localhost:3030. Changes to `labspace/` are visible without restart.

## Lab structure

| Module | Title | Terminal? |
|---|---|---|
| 00 | Pre-flight Checklist | Host terminal |
| 01 | Why AI Agents Need Governance | Reading only |
| 02 | Your First Sandbox | Sandbox terminal |
| 03 | **The Isolation Proof** ⭐ | Both terminals |
| 04 | Secrets Without Exposure | Both terminals |
| 05 | Network Policy | Both terminals |
| 06 | Branch Mode | Both terminals |
| 07 | Parallel Agents | Multiple terminals |
| 08 | AI Governance at Enterprise Scale | Reflection |

## Publishing

1. Add `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` as repository secrets
2. Update `DOCKERHUB_REPO` in `.github/workflows/publish-labspace.yaml.temp`
3. `mv .github/workflows/publish-labspace.yaml.temp .github/workflows/publish-labspace.yaml`

## Related

- [dockersamples/sbx-quickstart](https://github.com/dockersamples/sbx-quickstart) — the DevBoard app used in exercises
- [docker/sbx-releases](https://github.com/docker/sbx-releases) — sbx CLI releases
- [docs.docker.com/ai/sandboxes](https://docs.docker.com/ai/sandboxes/) — official documentation
