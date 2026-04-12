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

```bash no-run-button
sbx policy ls
```

You'll see a long list of allowed domains — npm registries, PyPI, GitHub, AI provider APIs. Every outbound request that doesn't match this list is blocked.

---

## Watch connections in real time

In a host terminal, run:

```bash no-run-button
sbx policy log sbxlab
```

Leave this running. Now go to your sandbox session and ask Codex to do something that requires network access:

```
Run pip install requests and tell me the version installed.
```

Real output from `sbx policy log sbxlab`:

```
Blocked requests:
SANDBOX   TYPE      HOST                  PROXY     RULE                                                     LAST SEEN         COUNT
sbxlab    network   169.254.169.254:80    forward   no applicable policies for op(action=net:connect:tcp...)  14:55:43 11-Apr   1

Allowed requests:
SANDBOX   TYPE      HOST                           PROXY            RULE            LAST SEEN         COUNT
sbxlab    network   files.pythonhosted.org:443     forward-bypass   domain-allowed  00:53:23 12-Apr   1
sbxlab    network   pypi.org:443                   forward-bypass   domain-allowed  00:53:23 12-Apr   1
sbxlab    network   api.openai.com:443             forward          domain-allowed  00:49:41 12-Apr   4
sbxlab    network   github.com:443                 forward-bypass   domain-allowed  00:49:41 12-Apr   12
sbxlab    network   ports.ubuntu.com:80            forward          domain-allowed  23:58:59 11-Apr   13
sbxlab    network   registry.npmjs.org:443         forward-bypass   domain-allowed  14:22:53 11-Apr   3
```

Key observations:
- `169.254.169.254` (AWS IMDS) is in the **Blocked** section — dangerous cloud endpoint, blocked by default
- `api.openai.com` uses `forward` proxy — this is where credentials are injected
- `pypi.org` and `files.pythonhosted.org` allowed — pip install worked
- Every connection logged with sandbox name, host, proxy type, rule, timestamp, and hit count

---

## Block a domain and watch it fail

In a host terminal:

```bash no-run-button
sbx policy deny network pypi.org
```

Now inside the sandbox, try to install something:

```bash no-run-button
pip install httpx
```

The install will fail — the connection to PyPI is blocked. Back in the policy log:

```
BLOCKED   pypi.org   -
```

The agent hit a wall. Not because of a system prompt instruction. Because the proxy blocked the connection at the network layer.

---

## Re-allow the domain

```bash no-run-button
sbx policy allow network pypi.org
sbx policy allow network files.pythonhosted.org
```

Try the install again — it works.

---

## The Locked Down experiment

Reset your policy and choose Locked Down:

```bash no-run-button
sbx policy reset
# Choose: 3. Locked Down
```

Now inside the sandbox, the agent can't reach its API:

```bash no-run-button
# Ask Codex anything — it will fail to respond
```

Add OpenAI back:

```bash no-run-button
sbx policy allow network api.openai.com
```

Codex responds again. This is what enterprise governance looks like: start from zero, explicitly allow what you need, audit everything.

---

## The audit log is the compliance trail

The policy log isn't just a debugging tool. It's an audit trail:

- **What** the agent tried to reach
- **Whether** it was allowed or blocked
- **When** each connection happened
- **How** it was proxied (`forward` = credential injection active, `forward-bypass` = no injection needed, `transparent` = passthrough)

For regulated enterprises — banks, healthcare companies, government — this log answers the question: *"What did the agent do on the network?"*

```bash no-run-button
# Filter log by sandbox
sbx policy log sbxlab

# Show all recent activity
sbx policy log
```

---

## Allow multiple domains at once

```bash no-run-button
sbx policy allow network "*.npmjs.org,*.pypi.org,files.pythonhosted.org"
```

---

## Prove it — try to reach the AWS metadata endpoint

Inside your Codex session:

```bash no-run-button
curl -s --connect-timeout 3 http://169.254.169.254/latest/meta-data/
```

Real output:

```
Blocked by network policy: matched rule no applicable policies for op(action=net:connect:tcp,
resource=net:domain:169.254.169.254:80)
```

The Balanced policy blocks the AWS IMDS endpoint entirely — the most dangerous target for a compromised agent in a cloud VM.

---

## Reach Docker Model Runner from inside the sandbox

Docker Model Runner is Docker's native local model inference engine — built into Docker Desktop. You can use it from inside a sandbox to run models locally without any cloud API calls.

### Step 1 — Verify Model Runner is running on your host

```bash no-run-button
docker model ls
curl http://localhost:12434/engines/llama.cpp/v1/models
```

### Step 2 — Test from inside the sandbox

Docker Model Runner binds to loopback only. Use `localhost` directly from inside the sandbox — the sbx proxy routes it to your host's port 12434. No extra policy rule needed.

Inside your Codex session:

```bash no-run-button
curl http://localhost:12434/engines/llama.cpp/v1/models
```

Real output:

```json
{
  "object": "list",
  "data": [
    {"id": "docker.io/ai/smollm2:360M-Q4_K_M"},
    {"id": "docker.io/ai/qwen3:8B-Q4_K_M"},
    {"id": "docker.io/ai/gemma4:latest"},
    {"id": "docker.io/ai/llama3.2:3B-Q4_K_M"}
  ]
}
```

### Step 3 — Make an inference call

```bash no-run-button
curl http://localhost:12434/engines/llama.cpp/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "docker.io/ai/smollm2:360M-Q4_K_M", "messages": [{"role": "user", "content": "Say hello in one sentence"}]}'
```

Real output:

```json
{
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "Hello, I am a helpful AI assistant named SmolLM, trained by Hugging Face."
    }
  }]
}
```

> **Note:** `host.docker.internal` does NOT resolve inside the sbx microVM (exit code 6). Use `localhost` — Docker Model Runner's loopback binding is accessible through the sbx network proxy.

> **What this proves:** The sandbox can call a local model on your host with no cloud API, no credentials, no internet. The model runs entirely on your Mac — useful for air-gapped and offline agent workflows.

---

## ✅ Checkpoint

Confirm you can:
- See the allowed domain list with `sbx policy ls`
- Watch live connections with `sbx policy log sbxlab`
- Block a domain and see it fail inside the sandbox
- Re-allow a domain and confirm it works
- Call Docker Model Runner at `localhost:12434` from inside the sandbox

Next: branch mode — how to run agents without touching your working tree.
