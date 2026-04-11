# Network Policy

The sandbox controls what the agent can reach on the network. This is the third layer of isolation — and it's also the audit trail.

---

## Three policy modes

When you first ran `sbx login`, you chose a network policy:

| Mode | Behaviour |
|---|---|
| **Open** | All outbound traffic allowed |
| **Balanced** | Default deny, with common dev sites allowed (npm, pip, GitHub, AI APIs) |
| **Locked Down** | Everything blocked unless you explicitly allow it |

For this module, we'll work with **Balanced** — the default for most developers. You can always switch with `sbx policy reset`.

---

## See what's currently allowed

In a host terminal:

```bash
sbx policy ls
```

You'll see a long list of allowed domains — npm registries, PyPI, GitHub, AI provider APIs. Every outbound request that doesn't match this list is blocked.

---

## Watch connections in real time

In a host terminal, run:

```bash
sbx policy log sbxlab
```

Leave this running. Now go to your sandbox session and ask Claude to do something that requires network access:

```
Run pip install requests and tell me the version installed.
```

Watch the policy log. You'll see:

```
ALLOWED   files.pythonhosted.org   200
ALLOWED   pypi.org                 200
```

Every connection — allowed or blocked — is logged with a timestamp.

---

## Block a domain and watch it fail

In a host terminal:

```bash
sbx policy deny network pypi.org
```

Now inside the sandbox, try to install something:

```bash
pip install httpx
```

The install will fail — the connection to PyPI is blocked. Back in the policy log:

```
BLOCKED   pypi.org   -
```

The agent hit a wall. Not because of a system prompt instruction. Because the proxy blocked the connection at the network layer.

---

## Re-allow the domain

```bash
sbx policy allow network pypi.org
sbx policy allow network files.pythonhosted.org
```

Try the install again — it works.

---

## The Locked Down experiment

Reset your policy and choose Locked Down:

```bash
sbx policy reset
# Choose: 3. Locked Down
```

Now inside the sandbox, Claude can't reach Anthropic's API:

```bash
# Ask Claude anything — it will fail to respond
```

Add Anthropic back:

```bash
sbx policy allow network api.anthropic.com
```

Claude responds again. This is what enterprise governance looks like: start from zero, explicitly allow what you need, audit everything.

---

## The audit log is the compliance trail

The policy log isn't just a debugging tool. It's an audit trail:

- **What** the agent tried to reach
- **Whether** it was allowed or blocked  
- **When** each connection happened

For regulated enterprises — banks, healthcare companies, government — this log answers the question: *"What did the agent do on the network?"*

```bash
# Filter log by sandbox
sbx policy log sbxlab

# Show all recent activity
sbx policy log
```

---

## Allow multiple domains at once

```bash
sbx policy allow network "*.npmjs.org,*.pypi.org,files.pythonhosted.org"
```

---

## Reach host services from inside the sandbox

If you have a local service running on your Mac (like Ollama), you can't use `localhost` from inside the VM — that resolves to the VM itself. Use `host.docker.internal` instead:

```bash
sbx policy allow network localhost:11434
```

Then inside the sandbox, point your client at `host.docker.internal:11434`.

---

## ✅ Checkpoint

Confirm you can:
- See the allowed domain list with `sbx policy ls`
- Watch live connections with `sbx policy log sbxlab`
- Block a domain and see it fail inside the sandbox
- Re-allow a domain and confirm it works

Next: branch mode — how to run agents without touching your working tree.
