# Your First Sandbox

Time to get hands-on. In this module you'll start your sandbox, explore the architecture from inside and outside the VM, and get Claude authenticated.

---

## Start the sandbox

From your host terminal, in `~/sbx-lab`:

```bash
sbx run sbxlab
```

The first run pulls the Claude Code image — this takes 1–2 minutes. Subsequent starts reuse the cached image and take seconds.

You'll see the Claude Code interface load inside your terminal.

---

## Authenticate Claude

Inside the Claude session, run:

```
/login
```

- If you have a **Claude Max / Pro subscription**: login with your email (e.g. `yourname@gmail.com`)
- If you have an **API key**: it was already injected via the proxy — no `/login` needed

You only need to do this once — credentials persist in the sandbox.

---

## Explore the codebase

Once authenticated, give Claude this prompt:

```
Explore this codebase and give me:
1. A summary of the architecture and tech stack
2. How to run it locally without Docker Compose
3. What the test suite covers
4. Any obvious issues or areas of concern
```

Claude will read the source files and report back. Watch it work — it's reading the actual files from your `~/sbx-lab` directory.

---

## What's happening under the hood

While Claude is working, open a **second terminal on your host** and run:

```bash
# These show the sandbox is a VM, not a container
docker ps          # sbxlab does NOT appear here
sbx ls             # sbxlab appears HERE instead
```

This is the first hint of the architecture. The sandbox isn't a container on your host — it's a VM. That distinction matters, and you'll prove it hands-on in the next module.

---

## Understanding the workspace mount

Your `~/sbx-lab` directory is mounted into the VM at the same absolute path. This means:

- **Changes you make on the host** appear instantly inside the sandbox
- **Changes Claude makes inside the sandbox** appear instantly on your host
- **Nothing else from your host** is accessible inside the VM

Open one of the source files in your editor on the host. Make a small change and save it. Then ask Claude inside the sandbox to read that file. It sees your change immediately — no sync delay, no copy step.

---

## Controlling the session

| Action | Command |
|---|---|
| Exit the Claude session | Press `Ctrl-C` twice |
| Run a shell command without leaving Claude | Type `!` before the command: `!ls` |
| Open the interactive dashboard | Run `sbx` with no arguments (new terminal) |

---

## The interactive TUI dashboard

In a separate host terminal, run:

```bash
sbx
```

The dashboard shows your sandboxes as cards with live CPU and memory usage. Press `Tab` to switch to the **Network panel** — a live log of every outbound connection the sandbox makes.

Press `Ctrl-C` then `Y` to exit without stopping your sandboxes.

---

## ✅ Checkpoint

Before moving on, confirm:
- `sbx run sbxlab` worked and Claude responded
- `docker ps` on the host shows no sandbox
- `sbx ls` on the host shows `sbxlab`
- Claude can read the codebase files

Next: the isolation proof — where you'll systematically try to break out of the VM.
