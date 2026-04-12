#!/bin/bash
# update-labspace-sbx.sh
#
# Run from the root of your freshly cloned labspace-sbx:
#   cd labspace-sbx
#   bash update-labspace-sbx.sh
#
# What it does:
#   1. Flattens 05-network-policy/index.md → 05-network-policy.md
#   2. Rewrites 05-network-policy.md with correct sbx behavior
#   3. Updates labspace.yaml to use flat file paths
#   4. Updates compose.override.yaml with correct sbx setup
#   5. Updates start.sh with clean ttyd launcher
#   6. Disables Run button on all code blocks (keeps Copy)
#   7. Commits and pushes everything

set -e

BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; RESET='\033[0m'
log() { echo -e "\n${CYAN}==>${RESET} ${BOLD}$1${RESET}"; }
ok()  { echo -e "  ${GREEN}✓${RESET} $1"; }

# Guard
if [ ! -d "labspace" ]; then
  echo "ERROR: Run from the root of your labspace-sbx clone."
  exit 1
fi

# ── 1. Flatten folder structure ───────────────────────────────────────────────
log "Flattening labspace folder structure..."

for folder in labspace/*/; do
  [ -f "${folder}index.md" ] || continue
  base=$(basename "$folder")
  flat="labspace/${base}.md"
  mv "${folder}index.md" "$flat"
  rm -rf "$folder"
  ok "Flattened $folder → $flat"
done

# ── 2. Rewrite 05-network-policy.md ──────────────────────────────────────────
log "Rewriting labspace/05-network-policy.md..."

cat > labspace/05-network-policy.md << 'EOF'
# Network Policy

The sandbox controls what the agent can reach on the network. This is the third
layer of isolation — and it gives you a complete audit trail of every connection
the agent attempts.

---

## The default: already open for common dev tools

sbx ships with **5 default allow policies** covering everything a developer
typically needs. You don't need to configure anything for standard workflows.

Check what's allowed right now:

```bash no-run-button
sbx policy ls
```

You'll see five policy groups:

| Policy | What it covers |
|---|---|
| `default-ai-services` | OpenAI, Anthropic, Gemini, Cursor, Perplexity |
| `default-package-managers` | PyPI, npm, cargo, maven, rubygems, and more |
| `default-code-and-containers` | GitHub, GitLab, Docker Hub, ghcr.io |
| `default-cloud-infrastructure` | AWS, GCP, Azure, Vercel, Fastly |
| `default-os-packages` | Ubuntu, Debian, Alpine package repos |

`pypi.org`, `files.pythonhosted.org`, `npmjs.org`, `github.com` — all already
allowed. No setup required.

---

## Prove it: install a package

Start your sandbox and ask the agent to install `httpx`:

```bash no-run-button
sbx run sbxlab
```

Then prompt:

> Install httpx and tell me the version

The agent will work through PEP 668 on its own and successfully install:

```plaintext no-copy-button
• Ran python3 -m pip install httpx
  └ error: externally-managed-environment ...

• Ran python3 -m pip install --break-system-packages httpx
  └ Successfully installed httpx-0.28.1
    0.28.1
```

The agent self-corrected and got the answer — all inside the microVM, your Mac
untouched.

---

## The real power: deny rules

The default policies allow common tools. But you can **restrict** what the agent
can reach — blocking specific domains at the network layer, regardless of what
the agent tries.

### Step 1 — Block PyPI

```bash no-run-button
sbx policy deny network pypi.org
```

Verify it's active:

```bash no-run-button
sbx policy ls
```

You'll see a new local entry at the bottom:

```plaintext no-copy-button
local:9701dc6e-...   network   deny   pypi.org
```

### Step 2 — Restart the sandbox

Policy changes require a sandbox restart to take effect:

```bash no-run-button
sbx stop sbxlab
sbx run sbxlab
```

### Step 3 — Watch the agent fail

Ask the agent to install a package:

> Install requests and tell me the version

The agent is persistent — it will try multiple approaches, all of which fail:

```plaintext no-copy-button
• Ran pip install requests
  └ error: externally-managed-environment

• Ran pip install --break-system-packages requests
  └ ERROR: Could not find a version that satisfies the requirement requests
    ERROR: No matching distribution found for requests

• Ran curl -I https://pypi.org/simple/requests/
  └ HTTP/2 403
```

The agent tried everything it knew. It still failed. Not because of a system
prompt instruction — because the proxy blocked the TCP connection at the network
layer.

> **Key insight:** A smarter agent cannot bypass a network deny rule.
> Agent capability and network policy are completely independent layers.

### Step 4 — Find and remove the deny rule

List policies to get the rule ID:

```bash no-run-button
sbx policy ls
```

Look for the local deny entry at the bottom. Copy its UUID (the part after
`local:`), then remove it:

```bash no-run-button
sbx policy rm network --id <uuid-from-policy-ls>
```

> **Important:** Use `--id` with just the UUID — drop the `local:` prefix.

Verify it's gone:

```bash no-run-button
sbx policy ls
```

No local entries should remain.

### Step 5 — Confirm the agent works again

Restart the sandbox:

```bash no-run-button
sbx stop sbxlab
sbx run sbxlab
```

Ask the agent to install requests again — it works immediately.

---

## Key rules about policy precedence

- **Deny overrides allow** — a local deny rule beats any default allow policy
- **Restart required** — policy changes take effect on the next `sbx run`
- **Always clean up deny rules** — use `sbx policy rm network --id <uuid>`
- **Default policies cannot be removed** — only local rules you add can be removed

---

## Watch live connections

In a separate terminal, watch every outbound connection in real time:

```bash no-run-button
sbx policy log sbxlab
```

You'll see each connection as it happens:

```plaintext no-copy-button
ALLOWED   pypi.org                 200
ALLOWED   files.pythonhosted.org   200
```

Add a deny rule and repeat — you'll see:

```plaintext no-copy-button
BLOCKED   pypi.org   -
```

This log is your **audit trail**. For regulated enterprises it answers:
*"What did the agent do on the network, and when?"*

---

## Reach host services from inside the sandbox

If you have a local service running on your Mac (like Ollama on port 11434),
use `host.docker.internal` — not `localhost`, which resolves to the VM itself:

```bash no-run-button
sbx policy allow network localhost:11434
```

Then inside the sandbox, connect to `host.docker.internal:11434`.

---

## ✅ Checkpoint

Before moving on, confirm you can:

- Run `sbx policy ls` and identify the 5 default policy groups
- Add a deny rule and observe the agent failing
- Remove the deny rule with `sbx policy rm network --id <uuid>`
- Confirm the agent works again after the deny rule is removed

Next: branch mode — how to run agents without touching your working tree.
EOF

ok "labspace/05-network-policy.md rewritten"

# ── 3. Update labspace.yaml ───────────────────────────────────────────────────
log "Updating labspace/labspace.yaml..."

cat > labspace/labspace.yaml << 'EOF'
metadata:
  id: ajeetraina/labspace-sbx
  sourceRepo: github.com/ajeetraina/labspace-sbx
  contentVersion: abcd123

title: Running AI Agents Safely with Docker Sandboxes
description: |
  Learn how to run AI coding agents in isolated microVM sandboxes using Docker sbx.
  Go hands-on with structural isolation, credential proxy injection, network policy
  enforcement, branch mode, and parallel agent execution. Prove the security
  guarantees yourself with real commands against real file paths.

services:
  - title: Term 1
    id: ide
    url: http://localhost:8085
    icon: terminal
  - title: Term 2
    id: term2
    url: http://localhost:8085
    icon: terminal

sections:
  - title: Pre-flight Checklist
    contentPath: 00-preflight.md
  - title: Why Agents Need Governance
    contentPath: 01-why-governance.md
  - title: Your First Sandbox
    contentPath: 02-first-sandbox.md
  - title: "The Isolation Proof \U0001F525"
    contentPath: 03-isolation-proof.md
  - title: Secrets Without Exposure
    contentPath: 04-secrets.md
  - title: Network Policy
    contentPath: 05-network-policy.md
  - title: Branch Mode
    contentPath: 06-branch-mode.md
  - title: Parallel Agents
    contentPath: 07-parallel-agents.md
  - title: AI Governance at Scale
    contentPath: 08-governance-summary.md
EOF

ok "labspace/labspace.yaml updated"

# ── 4. Update compose.override.yaml ──────────────────────────────────────────
log "Updating compose.override.yaml..."

cat > compose.override.yaml << 'EOF'
services:
  configurator:
    environment:
      PROJECT_CLONE_URL: https://github.com/ajeetraina/labspace-sbx

  # Dummy workspace - satisfies depends_on, Mac terminal owns port 8085
  workspace:
    image: ajeetraina/labspace-workspace-ttyd:latest
    pull_policy: never
    ports: !override []
    environment:
      PORT: "8086"

  interface:
    image: ajeetraina/labspace-interface-sbx:latest
    pull_policy: never
    environment:
      WORKSPACE_TYPE: ttyd
EOF

ok "compose.override.yaml updated"

# ── 5. Update start.sh ───────────────────────────────────────────────────────
log "Updating start.sh..."

cat > start.sh << 'EOF'
#!/bin/bash
# start.sh - Launch the sbx Labspace
#
# Prerequisites:
#   brew install ttyd
#   brew install docker/tap/sbx

set -e

TTYD_PORT=8085

if ! command -v ttyd &>/dev/null; then
  echo "ERROR: ttyd not found. Install with: brew install ttyd"
  exit 1
fi

if ! command -v sbx &>/dev/null; then
  echo "ERROR: sbx not found. Install with: brew install docker/tap/sbx"
  exit 1
fi

echo "==> Clearing port $TTYD_PORT..."
lsof -ti tcp:$TTYD_PORT | xargs kill -9 2>/dev/null || true
sleep 1

echo "==> Starting terminal on port $TTYD_PORT..."
ttyd -p $TTYD_PORT --writable zsh &
TTYD_PID=$!
sleep 1

if ! lsof -ti tcp:$TTYD_PORT &>/dev/null; then
  echo "ERROR: ttyd failed to start on port $TTYD_PORT"
  exit 1
fi
echo "    ttyd PID: $TTYD_PID"

echo "==> Starting Labspace..."
docker compose \
  -f oci://dockersamples/labspace \
  -f compose.override.yaml \
  up &
COMPOSE_PID=$!

echo ""
echo "==========================================="
echo "  Labspace ready at http://localhost:3030"
echo "  Term 1 / Term 2 → your Mac terminal"
echo "  Run: sbx ls, sbx version, etc."
echo "==========================================="
echo ""
echo "Press Ctrl+C to stop"

cleanup() {
  echo "Stopping..."
  kill $TTYD_PID 2>/dev/null || true
  docker compose \
    -f oci://dockersamples/labspace \
    -f compose.override.yaml \
    down 2>/dev/null || true
}
trap cleanup EXIT
wait $COMPOSE_PID
EOF

chmod +x start.sh
ok "start.sh updated"

# ── 6. Disable Run button on all code blocks ─────────────────────────────────
log "Disabling Run button on all code blocks..."

for f in labspace/*.md; do
  [ -f "$f" ] || continue
  perl -i -pe '
    s/^```bash\s*$/```bash no-run-button\n/g;
    s/^```sh\s*$/```sh no-run-button\n/g;
    s/^```console\s*$/```console no-run-button\n/g;
  ' "$f"
  ok "$f"
done

# ── 7. Commit and push ────────────────────────────────────────────────────────
log "Committing changes..."

git add .
git status --short

echo ""
read -p "Commit and push to GitHub? (y/n) " confirm
if [[ "$confirm" == "y" ]]; then
  git commit -m "fix: flatten folder structure, rewrite network policy, update start.sh"
  git push origin main
  echo -e "\n${GREEN}✓ Pushed to GitHub${RESET}"
else
  echo "Staged but not committed. Run 'git commit' when ready."
fi

echo ""
echo -e "${BOLD}Done! To launch the labspace:${RESET}"
echo ""
echo "  bash start.sh"
echo ""
