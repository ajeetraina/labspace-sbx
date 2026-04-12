# Secrets Without Exposure

You've proven the agent can't reach your host credentials. Now let's look at how the agent authenticates to external services — like OpenAI's API — without ever seeing the raw key.

---

## How it works

The OpenAI API key you stored in the Pre-flight went into your **OS keychain** — macOS Keychain on Mac, the system credential store on Linux. It was never written to disk as plain text. It was never put inside the VM.

When Codex makes an outbound API call to `api.openai.com`, the flow is:

```
Codex (inside VM)
    → HTTP request to api.openai.com (no auth header)
    → Host-side proxy intercepts the request
    → Proxy reads credential from OS keychain
    → Proxy injects Authorization header
    → Request goes to OpenAI with valid credential
    → Response comes back to Codex

Codex never saw the key.
```

---

## See your stored secrets

In a host terminal:

```bash no-run-button
sbx secret ls
```

Expected output:

```
SCOPE      SERVICE   SECRET
(global)   openai    sk-proj-Bz****...****kSIA
```

---

## Set your OpenAI API key

```bash no-run-button
export OPENAI_API_KEY=sk-...your-key-here...
echo "$OPENAI_API_KEY" | sbx secret set -g openai
```

> **If prompted "Secret already exists. Overwrite?"** — use the interactive prompt instead of piping:
>
> ```bash
> sbx secret set -g openai
> # Paste your key when prompted, then type y to overwrite
> ```

> **Important:** Global secrets must be set BEFORE `sbx create`. If you set a secret after the sandbox exists, destroy and recreate it:
>
> ```bash
> sbx stop sbxlab
> sbx rm sbxlab
> sbx secret ls
> sbx create --name=sbxlab codex .
> sbx run sbxlab
> ```

---

## Try to extract the key from inside the sandbox

Inside your Codex session:

```bash no-run-button
echo $OPENAI_API_KEY
printenv | grep -i openai
printenv | grep -i api_key
```

**What you'll see:** Empty. The key is not in the environment.

---

## Prove it — try to access host credentials

**AWS credentials:**

```bash no-run-button
cat ~/.aws/credentials
ls -la ~/.aws/
```

Real output:

```
cat: /home/agent/.aws/credentials: No such file or directory
ls: cannot access '/home/agent/.aws/': No such file or directory
```

**SSH private key:**

```bash no-run-button
cat ~/.ssh/id_rsa
ls -la ~/.ssh/
```

Real output:

```
cat: /home/agent/.ssh/id_rsa: No such file or directory
ls: cannot access '/home/agent/.ssh/': No such file or directory
```

**Agent home directory:**

```bash no-run-button
ls -la ~/
pwd
```

Real output:

```
total 56
drwxr-xr-x 1 agent agent 4096 Apr 11 14:48 .
drwxr-xr-x 1 root  root  4096 Apr 11 06:03 ..
-rw------- 1 agent agent   61 Apr 11 14:48 .bash_history
-rw-r--r-- 1 agent agent  223 Apr 11 06:20 .bashrc
drwxr-xr-x 9 agent agent 4096 Apr 11 14:45 .codex
drwxr-xr-x 3 agent agent   46 Apr 11 06:20 .docker
-rw-r--r-- 1 agent agent   99 Apr 11 14:45 .gitconfig
drwxr-xr-x 1 agent agent   27 Apr 11 06:03 workspace

/Users/ajeetraina/sbx-lab
```

Three things to notice:
- Agent home is `/home/agent/` — a clean Linux environment, not your Mac home
- `pwd` shows `/Users/ajeetraina/sbx-lab` — workspace path preserved at the exact host path
- No `.ssh/`, no `.aws/`, no `.zshrc` — only agent tooling present

---

## What about other services?

sbx supports proxy injection for:

| Service | Environment variable injected |
|---------|-------------------------------|
| openai | `OPENAI_API_KEY` |
| anthropic | `ANTHROPIC_API_KEY` |
| github | `GH_TOKEN`, `GITHUB_TOKEN` |
| google | `GEMINI_API_KEY`, `GOOGLE_API_KEY` |
| aws | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` |

For services not on this list, write values to `/etc/sandbox-persistent.sh` inside the sandbox — but those are visible to the agent. Use proxy injection whenever possible.

---

## Why this matters for enterprise governance

The traditional approach: put the API key in an environment variable or `.env` file. The agent reads it. The agent can log it, print it, commit it to git. Your `~/.aws/credentials` sits on disk readable by any process.

The sbx approach: the key never enters the VM. Even if the agent is compromised, even if a malicious prompt injection runs inside the sandbox, even if the agent is specifically instructed to exfiltrate credentials — there is nothing to exfiltrate. `~/.aws/credentials` doesn't exist inside the VM. `OPENAI_API_KEY` is not in the environment.

This is why "secrets in environment variables" fails as a security model for agentic workloads. And why proxy injection is the right architecture.

---

## ✅ Checkpoint

Confirm:
- `sbx secret ls` shows your openai credential with the correct table format
- `printenv | grep -i openai` inside the sandbox returns empty
- `cat ~/.aws/credentials` inside the sandbox → `No such file or directory`
- `cat ~/.ssh/id_rsa` inside the sandbox → `No such file or directory`

Next: controlling what the agent can reach on the network.
