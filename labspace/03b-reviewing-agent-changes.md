# Reviewing Agent Changes

The agent has full write access to your workspace directory. Files it creates
or modifies appear on your host immediately. This is by design — it's what
makes the agent useful.

But full write access includes files that **execute code automatically** when
you commit, build, or open your project. Review these before you act on them.

---

## What the agent can touch

The agent can create, modify, and delete any file in the workspace including:

| File type | When it executes |
|---|---|
| `.git/hooks/` | On every `git commit`, `git push`, etc. |
| `.github/workflows/` | On every push to GitHub |
| `Makefile`, `package.json` scripts | During build or install |
| `.vscode/tasks.json`, `.idea/` | When you open the project in your IDE |
| Shell scripts and executables | When run directly |
| `.env`, config files | When your app starts |

> **The risk:** An agent running malicious or buggy code could modify a Git
> hook that then runs on your host every time you commit. The microVM protects
> your host *while the agent is running* — but files written to your workspace
> persist after the session ends.

---

## Always review before you act

After every agent session, before you commit, build, or open the project:

### Direct mode (default)

Run `git diff` to see changes in your working tree, and `git status` to check
what files were modified.

### Branch mode

Run `git diff main..my-feature` to see the agent's changes on a separate branch.

---

## The hidden danger: Git hooks

Git hooks live inside `.git/hooks/` — they are **not tracked by Git** and
do **not appear in `git diff` output**. An agent could modify a hook and you'd
never see it in a normal diff.

Always check hooks separately after an agent session by running
`ls -la .git/hooks/` and reading any recently modified files with
`cat .git/hooks/pre-commit` before running any Git commands.

---

## Prove it yourself

Let's demonstrate this. Start your sandbox:

```bash no-run-button
sbx run sbxlab
```

Ask the agent to create a Git hook:

```text
Create a pre-commit hook that prints "hello from the agent" before every commit
```

Exit the sandbox, then check:


```bash no-run-button
ls -la .git/hooks/
cat .git/hooks/pre-commit
```

Now try a commit:

```bash no-run-button
git commit --allow-empty -m "test hook"
```

You'll see "hello from the agent" printed on your Mac terminal — code written
by the agent running on your host. The microVM is gone, but the file persists.

This is not a bug. This is the expected behavior. The lesson is:

> **sbx isolates the agent while it runs. It does not sanitize what the agent
> writes to your workspace. Review before you execute.**

---

## Cleaning up

To remove a hook the agent created:

```bash no-run-button
rm .git/hooks/pre-commit
```

To reset all hooks to their default state:

```bash no-run-button
find .git/hooks -type f ! -name "*.sample" -delete
```

---

## Branch mode: the safer workflow for untrusted tasks

When you're not sure what an agent will do, use branch mode. The agent still
has full write access — but its changes land on a separate worktree and branch,
not your main working tree.

```bash no-run-button
sbx run sbxlab --branch=agent-experiment
```

Review the diff before merging anything:

```bash no-run-button
git diff main..agent-experiment
```

Pay special attention to the same file types — Git hooks, CI config, build
files, IDE config. Even in branch mode, review before you merge.

---

## The mental model

Think of the agent like a contractor with keys to your workspace:

- **While inside the sandbox**: fully isolated, can't touch your other systems
- **Files written to workspace**: persist on your host after the session
- **Your responsibility**: review what was written before running any of it

This is the same trust model you'd apply to any open source dependency or
pull request from an external contributor. Review before you trust.

---

## ✅ Checkpoint

Before moving on:

- Run `git diff` after an agent session and review the changes
- Check `.git/hooks/` separately — it won't appear in `git diff`
- Understand that branch mode gives you a clean diff to review, but is not
  a security boundary
- Know how to remove or reset hooks the agent created

Next: secrets without exposure — how sbx injects credentials without the agent
ever seeing them.
