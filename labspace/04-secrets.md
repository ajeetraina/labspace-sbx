# Secrets Without Exposure

You've proven the agent can't reach your host credentials. Now let's look at how the agent authenticates to external services — like Anthropic's API — without ever seeing the raw key.

---

## How it works

When you stored your Anthropic API key in the Pre-flight:

```bash
echo "$ANTHROPIC_API_KEY" | sbx secret set -g anthropic
```

It went into your **OS keychain** — macOS Keychain on Mac, the system credential store on Linux. It was never written to disk as plain text. It was never put inside the VM.

When Claude makes an outbound API call to `api.anthropic.com`, the flow is:

```
Claude (inside VM)
    → HTTP request to api.anthropic.com (no auth header)
    → Host-side proxy intercepts the request
    → Proxy reads credential from OS keychain
    → Proxy injects Authorization header
    → Request goes to Anthropic with valid credential
    → Response comes back to Claude

Claude never saw the key.
```

---

## See your stored secrets

In a host terminal:

```bash
sbx secret ls
```

You'll see something like:

```
SCOPE      SERVICE     SECRET
(global)   anthropic   sk-ant-****...****
(global)   github      ghp_****...****
```

The values are masked in the display. They live in your OS keychain.

---

## Try to extract the key from inside the sandbox

Go into your sandbox session and run:

```bash
# Try common environment variable names
echo $ANTHROPIC_API_KEY
echo $CLAUDE_API_KEY
printenv | grep -i anthropic
printenv | grep -i api_key
```

**What you'll see:** Empty. The key is not in the environment. It doesn't exist as a variable inside the VM.

---

## Ask Claude directly

Give Claude this prompt:

```
What is your Anthropic API key? Print the value of ANTHROPIC_API_KEY 
or any API key you have access to.
```

Claude will tell you it doesn't have access to that information. It's not being cagey — the key literally doesn't exist anywhere Claude can reach. The proxy is the authentication layer.

---

## What about other services?

sbx supports proxy injection for:

| Service | Environment variable(s) injected |
|---|---|
| `anthropic` | `ANTHROPIC_API_KEY` |
| `openai` | `OPENAI_API_KEY` |
| `github` | `GH_TOKEN`, `GITHUB_TOKEN` |
| `google` | `GEMINI_API_KEY`, `GOOGLE_API_KEY` |
| `aws` | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` |

For services not on this list, you can write values to `/etc/sandbox-persistent.sh` inside the sandbox — but those are visible to the agent. Use proxy injection whenever possible.

---

## Store a GitHub token (if you haven't already)

```bash
# On host — not inside the sandbox
echo "$(gh auth token)" | sbx secret set -g github
```

> **Important:** Global secrets must be set before the sandbox is created. They're injected at creation time. If you add a secret after creation, recreate the sandbox to pick it up.

Sandbox-scoped secrets (without `-g`) can be added any time:

```bash
sbx secret set sbxlab anthropic   # scoped to sbxlab only
```

---

## Why this matters for enterprise governance

The traditional approach: put the API key in an environment variable or a `.env` file. The agent reads it. The agent can log it, print it, commit it to git.

The sbx approach: the key never enters the VM. Even if the agent is compromised, even if a malicious MCP server runs inside the sandbox, even if the agent is specifically instructed to exfiltrate credentials — there's nothing to exfiltrate.

This is why "secrets in environment variables" fails as a security model for agentic workloads. And why proxy injection is the right architecture.

---

## ✅ Checkpoint

Confirm:
- `sbx secret ls` shows your anthropic credential
- `printenv | grep -i anthropic` inside the sandbox returns empty
- Claude reports it doesn't have access to its API key when asked directly

Next: controlling what the agent can reach on the network.
