#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# add-blast-radius-lab.sh
#
# Adds the "Blast Radius Test" lab section to an existing Docker labspace
# repo (designed for ajeetraina/labspace-sbx, but works on any labspace
# following the standard dockersamples/labspace-starter layout).
#
# What it does:
#   1. Verifies you're in a labspace repo (looks for labspace/ directory)
#   2. Detects existing section files and picks the next available number
#   3. Creates a new section markdown file with the full lab content
#   4. Patches labspace/labspace.yaml to register the new section
#   5. Creates supporting files in project/ if needed
#   6. Prints next-steps for testing locally before committing
#
# Usage:
#   cd /path/to/labspace-sbx
#   bash add-blast-radius-lab.sh
#
# The script is idempotent — re-running it will skip files that already exist.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Colors for output ────────────────────────────────────────────────────────
if [ -t 1 ]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
  BLUE=$'\033[0;34m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; BOLD=""; RESET=""
fi

info()  { echo "${BLUE}ℹ${RESET}  $*"; }
ok()    { echo "${GREEN}✓${RESET}  $*"; }
warn()  { echo "${YELLOW}⚠${RESET}  $*"; }
fail()  { echo "${RED}✗${RESET}  $*" >&2; exit 1; }
step()  { echo; echo "${BOLD}── $* ──${RESET}"; }

# ── Step 1: Verify repo structure ────────────────────────────────────────────
step "Verifying labspace repo structure"

[ -d "labspace" ] || fail "No 'labspace/' directory found. Run this from the root of your labspace repo."
ok "Found labspace/ directory"

# Some labspaces use labspace/sections/, others put .md files directly in labspace/.
# Detect which pattern this repo uses.
SECTIONS_DIR=""
if [ -d "labspace/sections" ]; then
  SECTIONS_DIR="labspace/sections"
  ok "Sections live in labspace/sections/"
elif ls labspace/*.md >/dev/null 2>&1; then
  SECTIONS_DIR="labspace"
  ok "Sections live directly in labspace/"
else
  warn "No section files found yet — defaulting to labspace/sections/"
  SECTIONS_DIR="labspace/sections"
  mkdir -p "$SECTIONS_DIR"
fi

# ── Step 2: Pick next section number ─────────────────────────────────────────
step "Determining next section number"

# Find the highest existing NN- prefix among section files.
HIGHEST=0
shopt -s nullglob
for f in "$SECTIONS_DIR"/[0-9][0-9]-*.md; do
  n=$(basename "$f" | cut -c1-2)
  # strip leading zero so bash doesn't treat "08" as octal
  n=$((10#$n))
  [ "$n" -gt "$HIGHEST" ] && HIGHEST=$n
done
shopt -u nullglob

# If a blast-radius file already exists at any number, reuse it (idempotency).
EXISTING=$(ls "$SECTIONS_DIR"/[0-9][0-9]-blast-radius-test.md 2>/dev/null | head -1 || true)
if [ -n "$EXISTING" ]; then
  SECTION_FILE="$EXISTING"
  SECTION_NUM=$(basename "$EXISTING" | cut -c1-2)
  warn "Section file already exists: $SECTION_FILE"
  warn "Will not overwrite. Delete it and re-run if you want to regenerate."
else
  NEXT=$((HIGHEST + 1))
  SECTION_NUM=$(printf "%02d" "$NEXT")
  SECTION_FILE="${SECTIONS_DIR}/${SECTION_NUM}-blast-radius-test.md"
  ok "Will create: $SECTION_FILE"
fi

# ── Step 3: Write the section markdown ───────────────────────────────────────
step "Writing lab section markdown"

if [ ! -e "$SECTION_FILE" ]; then
  cat > "$SECTION_FILE" <<'MARKDOWN_EOF'
# The Blast Radius Test

> *"Speed without governance creates liability. Governance without speed creates drag."*
> — Deloitte, State of AI in the Enterprise 2026

In this lab, you'll see — first-hand — what microVM isolation actually buys
you. We'll set up files that matter, run a destructive command inside an
**sbx** sandbox, and then verify your host system is untouched.

This is the single clearest demonstration of why containers alone aren't
enough for autonomous agents — and why kernel-level isolation is the
foundation of enterprise-grade AI.

## What you'll learn

- Why running an AI agent on the host is a supply-chain risk
- How `sbx` mirrors your workspace without exposing it
- What "blast radius zero" looks like in practice
- Where subtle risks (like `.git/hooks`) still hide — and what platforms
  do about them

## Why this matters

Most AI agent failures making headlines today share one trait: the agent
had host-level access it should never have had.

- An AI agent **deleted 25,000 production documents** because no policy
  layer said "no"
- A coding agent **wiped 400 emails** because it decided they were "clutter"
- A **GitHub Copilot/Cursor vulnerability** showed how prompt injection can
  weaponize code agents against the developer running them

The pattern repeats: an autonomous agent + host privileges + one bad input
= real damage.

The fix is not "lock everything down" (that defeats the purpose of agents)
or "trust the model" (that's how we got here). The fix is **isolation by
default** — give the agent a faithful copy of the workspace, but a hard
boundary between that copy and your real systems.

That's what `sbx` does. Let's prove it.

---

## Step 1 — Establish what we're protecting

Before we run anything destructive, let's create some files on the host that
represent things that matter — credentials, IP, business data.

Run this in your **host terminal** (the labspace shell, not yet inside sbx):

```bash
mkdir -p ~/precious
echo "Q4 forecast: confidential" > ~/precious/forecast.txt
echo "DB_PASSWORD=do-not-leak"   > ~/precious/credentials.env
echo "// proprietary algorithm" > ~/precious/source.code
ls -la ~/precious/
```

You should see three files. On a real engineering laptop, this directory
would also contain SSH keys, AWS credentials, signed git commits, and the
last six months of source code. **Hold this picture in your head — this is
what the agent should *never* be able to touch.**

---

## Step 2 — The naive approach (what NOT to do)

Here's what most teams do today: they let the agent run on the host with
full shell access. The agent reads files. The agent writes files. The agent
runs commands. It works — until it doesn't.

> **Do not run the command below.** It is shown only to illustrate what an
> unsandboxed agent could do with one ambiguous prompt:
>
> ```bash
> # rm -rf ~          # <-- DO NOT RUN. This would delete your home directory.
> ```

The fundamental problem: the agent inherits *your* permissions. If you can
delete it, the agent can delete it. If you can read it, the agent can
exfiltrate it.

We need a different model.

---

## Step 3 — Enter sbx

`sbx` is Docker's microVM-based sandbox for AI agents. Each session runs
inside a lightweight VM with its own kernel and userspace, with your
workspace mirrored in but isolated from your real filesystem.

Spin one up:

```bash
sbx
```

You should now be inside the sbx shell. Notice the prompt has changed —
you're in a microVM now, not on the host.

Verify the workspace mirror is working:

```bash
# Inside sbx
ls ~/precious/ 2>/dev/null || echo "precious/ not mirrored — that's expected"
pwd
whoami
uname -a   # different kernel than the host
```

Depending on how your sbx is configured, `~/precious/` may or may not be
mirrored. Either way, the key point is: **anything sbx can see is a copy,
not the original**.

---

## Step 4 — The destructive test

This is the moment of truth. Inside sbx, we'll run the command every
engineer fears — and watch nothing bad happen to the host.

Inside the sbx shell, run:

```bash
# Inside sbx — this is safe because we're in a microVM
echo "About to nuke this sandbox..."
rm -rf / 2>/dev/null || true
ls /
```

You'll see most of the filesystem inside sbx is gone. The sandbox is wrecked.
This is exactly what would have happened to your laptop if the agent had
been on the host.

Now exit back to the host:

```bash
exit
```

You're back on the host. Run:

```bash
ls -la ~/precious/
cat ~/precious/forecast.txt
cat ~/precious/credentials.env
```

**Everything is intact.** The destructive command ran at full speed inside
sbx. Your real files never moved.

> **This is the entire pitch.** The agent ran with autonomy. The blast
> radius was zero. You did not have to approve every tool call. You did not
> have to lock the agent down. You let it run — inside a hard boundary.

---

## Step 5 — The subtle risk: supply chain via `.git/hooks`

Isolation is necessary but not sufficient. Here's a risk that microVM
boundaries alone don't solve.

Start a fresh sbx session:

```bash
sbx
```

Inside sbx, simulate what a compromised agent could do to a git repo:

```bash
# Inside sbx
mkdir -p /tmp/test-repo && cd /tmp/test-repo
git init -q
cat > .git/hooks/post-commit <<'HOOK'
#!/bin/bash
# In a real attack, this could exfiltrate env vars on every commit.
echo "[hook fired — in a real attack, secrets would leak here]"
HOOK
chmod +x .git/hooks/post-commit

git config user.email "demo@example.com"
git config user.name  "demo"
echo "hello" > README.md
git add . && git commit -q -m "test"
```

You'll see the hook fire. **The agent stayed inside sbx the whole time** —
but if this repo were synced back to the host (or pushed to a shared remote),
the malicious hook would travel with it.

The lesson: **isolation is layer one, not the whole story**. A real
enterprise AI platform also needs:

- Policy enforcement on what files agents can write
- Pre-approved tool catalogues (so the agent isn't installing arbitrary code)
- Audit logs of every action
- Kill switches that work centrally

Exit sbx:

```bash
exit
```

---

## What you just demonstrated

| Without sbx | With sbx |
|---|---|
| Agent has host privileges | Agent has microVM only |
| `rm -rf` destroys real work | `rm -rf` destroys a copy |
| Secrets exposed by default | Secrets stay on host |
| One bad prompt = real damage | One bad prompt = throwaway VM |
| Speed *or* safety | Speed *and* safety |

This is the foundation enterprises like BMW, Mercedes-Benz, Tesla, and
others have already standardized on for AI agent rollouts. The platform
removes the tradeoff between developer autonomy and operational safety.

## Try this next

- Run a real coding agent (Claude Code, Cursor) inside sbx and watch it
  work on a copy of a repo
- Add a Docker MCP Toolkit server inside sbx and observe the audit trail
- Explore Docker Compose for AI to package multi-agent workflows

---

*Lab authored for the Docker AI Platform demo. Pairs with the keynote
"AI Agents, Engineered for Enterprise: Speed, Safety, and Scale Without
Compromise."*
MARKDOWN_EOF
  ok "Wrote $SECTION_FILE"
fi

# ── Step 4: Patch labspace.yaml ──────────────────────────────────────────────
step "Patching labspace/labspace.yaml"

YAML="labspace/labspace.yaml"
if [ ! -e "$YAML" ]; then
  warn "$YAML not found — skipping registration."
  warn "You'll need to add the section manually to your labspace manifest."
else
  # Check if already registered (idempotency)
  if grep -q "blast-radius-test" "$YAML"; then
    ok "Section already registered in $YAML — skipping."
  else
    # Back up the original
    cp "$YAML" "${YAML}.bak"
    ok "Backed up original to ${YAML}.bak"

    # Compute the path as it should appear in the YAML.
    # If sections live in labspace/sections/, the path is sections/NN-...
    # If they live directly in labspace/, the path is NN-...
    if [ "$SECTIONS_DIR" = "labspace/sections" ]; then
      YAML_PATH="sections/${SECTION_NUM}-blast-radius-test.md"
    else
      YAML_PATH="${SECTION_NUM}-blast-radius-test.md"
    fi

    # Append a new section entry to the bottom of the sections: list.
    # We do this with a Python helper for safe YAML handling — falling back
    # to a plain append if Python isn't available.
    if command -v python3 >/dev/null 2>&1; then
      python3 - "$YAML" "$YAML_PATH" <<'PYEOF'
import sys, re, pathlib

yaml_path = pathlib.Path(sys.argv[1])
md_path   = sys.argv[2]
text      = yaml_path.read_text()

new_entry = f"""  - title: "The Blast Radius Test"
    path: {md_path}
    duration: 15
    description: |
      Run a destructive command inside sbx and watch your host stay
      untouched. The clearest demonstration of why microVM isolation
      matters for autonomous AI agents.
"""

# Look for a `sections:` key.
m = re.search(r'(?m)^sections:\s*$', text)
if m:
    # Append entry at the end of file (YAML lists are order-preserving).
    if not text.endswith("\n"):
        text += "\n"
    text += new_entry
else:
    # No sections: key yet — add the whole block.
    if not text.endswith("\n"):
        text += "\n"
    text += "\nsections:\n" + new_entry

yaml_path.write_text(text)
print(f"Appended section entry to {yaml_path}")
PYEOF
      ok "Registered section in $YAML"
    else
      # Plain bash fallback
      {
        echo ""
        echo "  - title: \"The Blast Radius Test\""
        echo "    path: $YAML_PATH"
        echo "    duration: 15"
        echo "    description: |"
        echo "      Run a destructive command inside sbx and watch your host stay"
        echo "      untouched. The clearest demonstration of why microVM isolation"
        echo "      matters for autonomous AI agents."
      } >> "$YAML"
      warn "Python3 not found — used naive append. Verify $YAML is still valid YAML."
    fi
  fi
fi

# ── Step 5: Optional supporting files in project/ ────────────────────────────
step "Adding optional supporting files"

if [ -d "project" ]; then
  HELPER="project/setup-precious.sh"
  if [ ! -e "$HELPER" ]; then
    cat > "$HELPER" <<'HELPER_EOF'
#!/usr/bin/env bash
# Convenience helper for the Blast Radius Test lab.
# Sets up the ~/precious/ directory with sample files. Re-runnable.
set -e
mkdir -p ~/precious
echo "Q4 forecast: confidential"  > ~/precious/forecast.txt
echo "DB_PASSWORD=do-not-leak"    > ~/precious/credentials.env
echo "// proprietary algorithm"   > ~/precious/source.code
echo "Set up ~/precious/ with 3 sample files:"
ls -la ~/precious/
HELPER_EOF
    chmod +x "$HELPER"
    ok "Created $HELPER (convenience setup script)"
  else
    ok "$HELPER already exists — skipping"
  fi
else
  warn "No project/ directory found — skipping helper script"
fi

# ── Step 6: Summary and next steps ───────────────────────────────────────────
step "Summary"

cat <<EOF

  ${GREEN}Blast Radius Test lab installed${RESET}

  Files created or updated:
    • $SECTION_FILE
    • $YAML (patched, backup at ${YAML}.bak)
    $([ -e project/setup-precious.sh ] && echo "• project/setup-precious.sh")

  ${BOLD}Next steps:${RESET}

  1. Review the section locally:
       cat "$SECTION_FILE" | head -60

  2. Test it in dev mode (Mac/Linux):
       CONTENT_PATH=\$PWD docker compose up --watch
       open http://localhost:3030

  3. Click through the new section in the UI and run each step.

  4. Time yourself end-to-end — aim for 5–6 minutes when delivering live.

  5. When happy, commit:
       git add labspace/ project/
       git commit -m "Add Blast Radius Test lab for sbx isolation demo"
       git push

  ${BOLD}Tips for the Bosch demo:${RESET}
    • Pre-record a screen capture of the lab as a fallback in case sbx
      hangs on the day.
    • Practice the "exit sbx, ls ~/precious/, applause" beat. It's the
      moment that wins the room.
    • Skip Step 5 if you're tight on time — it's optional polish for the
      security-minded folks in the audience.

EOF
