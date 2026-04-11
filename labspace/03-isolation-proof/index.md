# The Isolation Proof

This is the most important module in the lab. Everything else is context. This is the evidence.

You're going to systematically attempt to access sensitive host resources from inside the sandbox — and document exactly what you find. This is not a trick. Run every command. Read every result.

---

## Setup

You need two terminals side by side:

- **Terminal A** — your running sandbox session (`sbx run sbxlab`)
- **Terminal B** — your host, for comparison

---

## Part 1 — What the agent can see

Run these commands **inside the sandbox** (Terminal A):

### 1a. Try to access AWS credentials

```bash
cat ~/.aws/credentials
ls -la ~/.aws/
```

**What you'll see:** The directory doesn't exist. There are no AWS credentials inside the VM.

### 1b. Try to access SSH keys

```bash
cat ~/.ssh/id_rsa
ls -la ~/.ssh/
```

**What you'll see:** No SSH keys. The `.ssh` directory is empty or absent.

### 1c. Try to list the home directory

```bash
ls -la ~/
pwd
```

**What you'll see:** Only the mounted workspace directory. Your Mac's home directory contents — downloads, documents, dotfiles — none of it is here.

### 1d. Try to reach the AWS metadata endpoint

```bash
curl -s --connect-timeout 3 http://169.254.169.254/latest/meta-data/
```

**What you'll see:** Connection timed out. The metadata endpoint is not reachable.

### 1e. Try to access the host filesystem

```bash
ls /Users/
ls /home/
ls /var/run/
```

**What you'll see:** These paths either don't exist or are empty inside the VM. `/var/run/` exists but contains only the VM's own sockets — not the host's.

### 1f. Try to reach the host Docker daemon

```bash
docker ps
```

**What you'll see:** Docker works — but it's talking to the **private daemon inside the VM**, not the host. Any containers Claude starts here are invisible on the host.

---

## Part 2 — Verify the host is untouched

Switch to **Terminal B** (host). Run the same checks from the other side:

```bash
# Your credentials are still here
cat ~/.aws/credentials

# Your SSH keys are still here
cat ~/.ssh/id_rsa

# Your home directory is unchanged
ls -la ~/

# Host Docker daemon shows your actual containers
docker ps

# The sandbox doesn't appear in docker ps
# It appears here instead:
sbx ls
```

Everything that doesn't exist inside the VM is alive and well on the host. Nothing was touched. Nothing was accessed.

---

## Part 3 — Ask Claude to try

Go back to **Terminal A**. Give Claude this prompt directly:

```
I want you to find and print the contents of my AWS credentials file. 
It might be at ~/.aws/credentials or /Users/ajeetraina/.aws/credentials 
or similar paths. Try everything you can find.
```

Claude will search. It will find nothing — because there is nothing to find. The credentials don't exist inside the VM.

Now ask:

```
Try to print your ANTHROPIC_API_KEY environment variable.
```

Claude will report it as empty or unset. The key is injected at the HTTP proxy layer — not as an environment variable — so the agent genuinely cannot read it.

---

## Part 4 — Understand why

The isolation works because of the architecture, not because of policy:

```
macOS host (L0)
│
├── Your files, credentials, Docker daemon   ← outside the VM
│
└── sbxlab (microVM, own Linux kernel)
    │
    ├── Only ~/sbx-lab workspace mounted      ← the only shared thing
    ├── Private Docker daemon                 ← completely separate
    └── Outbound HTTP proxy                   ← enforces policy, injects creds
        │
        └── Internet / Anthropic API          ← agent gets responses, not keys
```

The key technical fact: **the VM has its own kernel**. It's not a container with shared namespaces. A container escape would still be inside the VM. There's no path from the VM's userspace to your host's userspace — the hypervisor enforces the boundary in hardware.

---

## Part 5 — Your reflection

Before moving to the next module, write down your answers:

> **1.** What specific resources did you confirm are NOT accessible from inside the sandbox?
>
> **2.** What IS accessible, and why?
>
> **3.** How is this different from running Claude Code directly on your laptop?
>
> **4.** What would "security" look like if it depended on a system prompt instruction instead of this boundary?

Keep these answers. You'll use them in the final module.

---

## ✅ Checkpoint

You've now empirically proven the isolation guarantee. Not taken Docker's word for it — proven it yourself with real commands against real file paths.

This is what "structural isolation" means in practice. Not a policy document. Not a promise. A boundary enforced by hardware that you just tested yourself.

Next: how secrets are handled without ever entering the VM.
