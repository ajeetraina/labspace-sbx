# Pre-flight Checklist

Before starting the lab, confirm your environment is ready. Every exercise depends on `sbx` running correctly on your host machine. **Do not skip this section.**

---

## Requirements

| Requirement | Platform |
|---|---|
| macOS Apple Silicon (M1/M2/M3/M4) | ✅ Fully supported |
| Linux x86_64 (Ubuntu 22.04+, KVM access) | ✅ Supported |
| macOS Intel | ❌ Not supported |
| Windows 11 x86_64 | ⚠️ Supported, some exercises differ |

---

## Step 1 — Verify sbx is installed

Open a terminal on your host machine and run:

```bash
sbx --version
```

Expected output: a version string like `sbx 0.21.0` or similar.

If you see `command not found`, install sbx first:

```bash
# macOS
brew install docker/tap/sbx

# Linux
curl -fsSL https://get.docker.com | sudo REPO_ONLY=1 sh
sudo apt-get install docker-sbx
sudo usermod -aG kvm $USER
newgrp kvm
```

---

## Step 2 — Verify you're logged in

```bash
sbx ls
```

If you see a login prompt or an authentication error, run:

```bash
sbx login
```

This opens a browser for Docker OAuth. Complete the flow and return here.

---

## Step 3 — Verify your Anthropic secret is stored

```bash
sbx secret ls
```

You should see an entry for `anthropic` in the output. If not:

```bash
echo "$ANTHROPIC_API_KEY" | sbx secret set -g anthropic
```

> **Why this matters:** Secrets are stored in your OS keychain and injected at the network proxy layer. The agent never sees the raw API key. This is one of the core governance guarantees you'll explore in Module 4.

---

## Step 4 — Clone the lab repository

The exercises use DevBoard — a full-stack FastAPI + Next.js issue tracker with intentional bugs. It's pre-configured for this lab.

```bash
git clone https://github.com/dockersamples/sbx-quickstart ~/sbx-lab
cd ~/sbx-lab
```

---

## Step 5 — Create your sandbox

```bash
sbx create --name=sbxlab claude .
sbx ls
```

You should see `sbxlab` in the list with status `stopped`. The sandbox is ready — you'll start it in the next module.

---

## ✅ Ready to go

All five checks pass? Move to Module 1.

If anything failed, check [Troubleshooting](https://docs.docker.com/ai/sandboxes/troubleshooting/) or the Appendix at the end of this lab.
