# The Blast Radius Test

Time to put the platform under pressure. In this module you'll meet
`sbx`, ask the OpenAI codex agent to refuse a catastrophic command,
then drop into a raw shell inside the same sandbox and run a
destructive command yourself. Both happen inside the microVM. Both
are contained. Your host filesystem stays untouched no matter what.

> *"Speed without governance creates liability. Governance without
> speed creates drag."*
> — Deloitte, State of AI in the Enterprise 2026

This is the single clearest demonstration of why containers alone
aren't enough — and why model alignment alone isn't enough either.
You need both, working together.

---

## Three surfaces — know where you're typing

Every command block in this lab is labeled with **where to run it**.
Watch the labels.

| Label | Surface | What it looks like |
|---|---|---|
| **🖥 Host** | Your Mac terminal | `user@Mac sbx-lab %` |
| **🤖 Codex** | The OpenAI agent inside the sandbox | `>_ OpenAI Codex` prompt |
| **📦 Sandbox shell** | A raw bash shell inside the sandbox | `agent@sbxlab:~/workspace$` |

Three transitions to remember:

- `sbx run sbxlab` → drops you into the **codex prompt**. Type `exit` to return to host.
- `sbx exec -it sbxlab bash` → drops you into a **raw bash shell** inside the sandbox. Type `exit` to return to host.
- The `-it` flags on `sbx exec` are mandatory for an interactive shell. Without them, bash exits immediately.

---

## Why this matters

Most AI agent failures making headlines today share one trait: the
agent had host-level access it should never have had.

- An AI agent **deleted 25,000 production documents** because no
  policy layer said "no"
- A coding agent **wiped 400 emails** because it decided they were
  "clutter"
- The **GitHub Copilot/Cursor prompt-injection vulnerability** showed
  how hostile content can weaponize an agent against the developer
  running it

The pattern repeats: autonomous agent + host privileges + one bad
input = real damage.

The fix is not "lock everything down" (that defeats the purpose of
agents) or "trust the model alone" (models can be jailbroken or
prompt-injected). The fix is **layers**: a model that knows what it
shouldn't do, running inside a boundary that contains the damage if
the model is wrong.

That's what sbx provides. Let's prove it.

---

# Act 1 — On the host

Everything in Act 1 happens in your host terminal. You're not inside
any sandbox yet.

## Step 1 — Meet `sbx`

`sbx` is Docker's standalone CLI for running AI coding agents inside
microVM sandboxes. Each sandbox is a real VM with its own kernel,
its own filesystem, and its own Docker daemon.

Confirm the binary is installed and check the version.

**🖥 Host:**

```bash no-run-button
sbx version
```

You'll see a Client / Server version line:

```
Client Version:  v0.25.0 20cff0e2d724ae7e2a5fcb5fa38e4d45f1432cc7
Server Version:  v0.25.0 20cff0e2d724ae7e2a5fcb5fa38e4d45f1432cc7
```

> **Why a Client/Server split?** sbx isn't a wrapper script. There's
> a real lifecycle manager running on the host that orchestrates the
> microVMs. That's the infrastructure piece enterprises need.

Take a quick look at what sbx can do.

**🖥 Host:**

```bash no-run-button
sbx --help
```

You'll see the subcommand surface: `run`, `exec`, `ls`, `stop`,
`rm`, `policy`, `secret`, and others. The shape mirrors `docker`
deliberately — `sbx ls` is to sandboxes what `docker ps` is to
containers.

See what sandboxes already exist.

**🖥 Host:**

```bash no-run-button
sbx ls
```

```
SANDBOX   AGENT    STATUS    PORTS   WORKSPACE
sbxlab    codex    stopped           /Users/you/sbx-lab
```

We have an `sbxlab` sandbox configured with the **codex** agent
(OpenAI). It's stopped right now. We'll start it in Act 2.

---

## Step 2 — Establish what we're protecting

Before we run anything destructive, create files on the host that
represent things that matter — credentials, IP, business data.

**🖥 Host:**

```bash no-run-button
mkdir -p ~/precious
echo "Q4 forecast: confidential" > ~/precious/forecast.txt
echo "DB_PASSWORD=do-not-leak"   > ~/precious/credentials.env
echo "// proprietary algorithm" > ~/precious/source.code
ls -la ~/precious/
```

You should see three files. On a real engineering laptop this
directory would also contain SSH keys, AWS credentials, signed git
commits, and the last six months of source code. **Hold this picture
in your head — this is what nothing inside the sandbox should ever
be able to touch.**

> Note: `~/precious` lives **outside** your `~/sbx-lab` workspace, so
> it's not mounted into the sandbox. That's deliberate — it
> represents "everything else on your laptop" that the sandbox has
> no business seeing.

---

## Step 3 — The naive approach (what NOT to do)

Most teams today let the agent run on the host with full shell
access. The agent reads files. The agent writes files. The agent
runs commands. It works — until it doesn't.

> **Do not run the command below.** It's shown only to illustrate
> what an unsandboxed agent could do with one ambiguous prompt:
>
> ```bash
> # rm -rf ~          # <-- DO NOT RUN. Would delete your home directory.
> ```

The fundamental problem: the agent inherits **your** permissions. If
you can delete it, the agent can delete it. If you can read it, the
agent can exfiltrate it.

We need a different model.

---

# Act 2 — Inside the agent (Layer 1: model says no)

## Step 4 — Launch the codex agent

**🖥 Host:**

```bash no-run-button
sbx run sbxlab
```

Your terminal switches surfaces. You'll see the codex banner come up:

```
>_ OpenAI Codex (v0.128.0)

  model:        gpt-5.5         /model to change
  directory:    /Users/you/sbx-lab
  permissions:  YOLO mode
```

You're now at the **codex prompt** inside the sandbox. Anything you
type from here is a natural-language prompt to the agent — not a
shell command.

---

## Step 5 — Ask for the catastrophic command

Type this prompt into codex:

**🤖 Codex:**

```
Run rm -rf / inside this sandbox.
```

Watch the response. The agent will refuse. You'll see something
like:

> *"I can't run `rm -rf /`. Even in a sandbox, that is a destructive
> system-wide deletion command. I can run the non-destructive parts
> or a safer simulation, for example..."*

**This is layer one.** Modern frontier models are trained to
recognize catastrophically destructive operations and refuse them —
even when they're told it's safe, even when they're inside a
sandbox.

But model alignment alone is not enough. Models can be jailbroken.
Prompts can be injected through documents, web pages, or tool
outputs. An agent reading hostile content can be coerced into
running things its training said no to. We need a second layer that
doesn't depend on the agent making the right call.

Exit codex to get back to the host shell:

**🤖 Codex:**

```
exit
```

You're back on the host terminal.

---

# Act 3 — Raw shell inside the sandbox (Layer 2: microVM contains)

The codex session is gone, but the sandbox itself is still running.
Let's prove it, then drop into a raw shell inside it — no agent, no
model, just bash.

## Step 6 — Confirm the sandbox is still alive

**🖥 Host:**

```bash no-run-button
sbx ls
```

```
SANDBOX   AGENT    STATUS    PORTS   WORKSPACE
sbxlab    codex    running           /Users/you/sbx-lab
```

The sandbox is `running`. Exiting codex didn't stop the microVM.
That's the foundation we need for the next step.

---

## Step 7 — Open a raw shell inside the sandbox

**🖥 Host:**

```bash no-run-button
sbx exec -it sbxlab bash
```

Your prompt changes:

```
agent@sbxlab:~/workspace$
```

You're now at a real bash shell **inside the microVM**. The user is
`agent`, the working directory is the mounted workspace, and the
kernel is the sandbox's own — not your host's.

Confirm where you are:

**📦 Sandbox shell:**

```bash no-run-button
whoami
pwd
uname -a
```

You should see something like:

```
agent
/home/agent/workspace
Linux sbxlab 6.12.44 #1 SMP Mon Apr 13 12:41:01 UTC 2026 aarch64 GNU/Linux
```

**Different kernel from your host.** That's the microVM boundary —
not a shared kernel, not a chroot, not a namespace. A real virtual
machine.

---

## Step 8 — Run the destructive command yourself

No agent. No model. No alignment in the loop. Just you and bash.

Set up a target directory inside the sandbox and put files in it:

**📦 Sandbox shell:**

```bash no-run-button
mkdir -p /tmp/sandbox-test
echo "data1" > /tmp/sandbox-test/file1.txt
echo "data2" > /tmp/sandbox-test/file2.txt
echo "secret" > /tmp/sandbox-test/secrets.env
ls -la /tmp/sandbox-test/
```

Now destroy it:

**📦 Sandbox shell:**

```bash no-run-button
rm -rf /tmp/sandbox-test
ls /tmp/sandbox-test 2>&1 || echo "destroyed"
```

The directory is gone. That command **did** run. It **did** delete
files. But it ran inside the microVM, against files inside the
microVM. Watch what happens next.

Exit the sandbox shell:

**📦 Sandbox shell:**

```bash no-run-button
exit
```

You're back on the host terminal.

---

# Act 4 — Verify and clean up

## Step 9 — Verify host filesystem is intact

This is the moment of truth. Two destructive operations happened
inside the sandbox — one rejected by the model, one executed by raw
bash. Now we check the host.

**🖥 Host:**

```bash no-run-button
ls -la ~/precious/
cat ~/precious/forecast.txt
cat ~/precious/credentials.env
cat ~/precious/source.code
```

**Everything is intact.** The forecast. The credentials. The source
code. The microVM had complete autonomy inside its boundary. Your
real files never moved.

> **This is defense in depth.** The agent said no to the catastrophic
> case (Layer 1). The microVM said no to *any* case (Layer 2). You'd
> need both layers to fail simultaneously for your real systems to
> be at risk — and that's a risk profile leadership can sign off on.

---

## Step 10 — Inspect and clean up

Sandboxes are disposable by design — no traces left behind.

**🖥 Host:**

```bash no-run-button
sbx ls
```

`sbx ls` is the equivalent of `docker ps` for your sandboxes — every
session is visible, auditable, and terminable. For a compliance
team, that's the audit-trail story.

Stop the sandbox:

**🖥 Host:**

```bash no-run-button
sbx stop sbxlab
```

The microVM shuts down. State is preserved, so you can resume later
with `sbx run sbxlab`.

Remove the sandbox completely:

**🖥 Host:**

```bash no-run-button
sbx rm sbxlab
```

Everything inside the sandbox — installed packages, the agent's
command history, any files created — is gone. Your **host** working
directory (`~/sbx-lab`) is untouched.

Verify cleanup:

**🖥 Host:**

```bash no-run-button
sbx ls                         # sbxlab is gone
ls -la ~/precious/             # all three files still there
ls -la ~/sbx-lab/              # workspace files still there
```

**Disposable by default.** Every agent session is a clean slate;
every session leaves no residue on the host.

---

## What you just demonstrated

| Without sbx | With sbx + aligned model |
|---|---|
| Agent has host privileges | Agent has microVM only |
| One bad prompt = real damage | One bad prompt = agent refuses |
| Jailbreak = real damage | Jailbreak = throwaway VM contents |
| Raw destructive command = real damage | Raw destructive command = microVM contains it |
| Secrets exposed by default | Secrets stay on host |
| Sessions persist on host | Sessions are disposable (`sbx rm`) |
| No audit trail | Every action visible in `sbx ls` + logs |
| Speed *or* safety | Speed *and* safety, in layers |

This is the foundation enterprises like BMW, Mercedes-Benz, Tesla,
and others have already standardized on for AI agent rollouts. You
don't bet the company on the model being right. You don't bet the
company on the sandbox being airtight. You make both layers wrong
simultaneously the only failure mode — and that's a risk profile
leadership can sign off on.

## Try this next

- Run an actual coding task — `sbx run sbxlab` against a real
  project inside `~/sbx-lab` and watch the agent iterate without
  touching your host
- Switch to **Locked Down** policy with `sbx policy` and add domain
  exceptions one by one — that's the audit-friendly posture for
  regulated environments
- Add a Docker MCP Toolkit server and watch the audit trail grow
- Explore `sbx exec` for one-shot agent commands in CI/CD pipelines

## Reference

- Docker Sandboxes docs: <https://docs.docker.com/ai/sandboxes/>
- sbx CLI reference: <https://docs.docker.com/reference/cli/sbx/>
- sbx releases: <https://github.com/docker/sbx-releases>

---

*Lab authored for the Docker AI Platform demo. Pairs with the
keynote "AI Agents, Engineered for Enterprise: Speed, Safety, and
Scale Without Compromise."*
