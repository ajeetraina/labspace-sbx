#!/bin/bash
# patch-lab5-sbx-login.sh
# Inserts the `sbx login` section into labspace/05-local-setup.md
# Run from the root of your labspace-docker-sandboxes repo clone.

set -e

FILE="labspace/05-local-setup.md"

if [ ! -f "$FILE" ]; then
  echo "Error: $FILE not found. Run this from the repo root."
  exit 1
fi

# The block to insert (after the `sbx version` code fence)
read -r -d '' LOGIN_BLOCK << 'BLOCK'

## Log in to Docker

Before running any sandbox, authenticate with your Docker account:

```bash
sbx login
```

The CLI prints a one-time device confirmation code and a URL:

```
Your one-time device confirmation code: XXXX-XXXX
Open this URL to sign in: https://login.docker.com/activate?user_code=XXXX-XXXX

Waiting for authentication...
Signed in as <your-docker-username>.
Daemon started (PID: XXXXX, socket: ~/Library/Application Support/com.docker.sandboxes/sandboxd/sandboxd.sock)
Logs: ~/Library/Application Support/com.docker.sandboxes/sandboxd/daemon.log
```

Open the URL in your browser, authenticate, and the CLI confirms sign-in automatically.

### Choose a network policy

After login, sbx prompts you to set a **default network policy** for all sandboxes:

```
Select a default network policy for your sandboxes:

  1. Open        — All network traffic allowed, no restrictions.
  2. Balanced    — Default deny, with common dev sites allowed.
  3. Locked Down — All network traffic blocked unless you allow it.

  Use ↑/↓ or 1–3 to navigate, Enter to confirm, Esc to cancel.
```

| Policy | Best for |
|--------|----------|
| Open | Local dev with no external exposure concerns |
| **Balanced** | **Recommended — least privilege without breaking typical dev workflows** |
| Locked Down | High-security or air-gapped environments |

> **Note:** The network policy is set once at login time and applies to all sandboxes on this machine.

BLOCK

# Insert the block after the line containing `sbx version` (inside the code fence closing ```)
# Strategy: find the line number of the closing ``` after `sbx version`, insert after it.

MARKER='sbx version'
LINE_NUM=$(grep -n "$MARKER" "$FILE" | head -1 | cut -d: -f1)

if [ -z "$LINE_NUM" ]; then
  echo "Error: Could not find '$MARKER' in $FILE"
  exit 1
fi

# The closing ``` of the sbx version block is the next ``` after MARKER
CLOSE_NUM=$(tail -n +"$((LINE_NUM + 1))" "$FILE" | grep -n '^\`\`\`$' | head -1 | cut -d: -f1)
INSERT_AFTER=$((LINE_NUM + CLOSE_NUM))

echo "Inserting sbx login block after line $INSERT_AFTER of $FILE"

# Split and reassemble
head -n "$INSERT_AFTER" "$FILE" > /tmp/lab5_top.md
echo "$LOGIN_BLOCK" >> /tmp/lab5_top.md
tail -n +"$((INSERT_AFTER + 1))" "$FILE" >> /tmp/lab5_top.md

mv /tmp/lab5_top.md "$FILE"

echo "Done. Previewing the inserted section:"
echo "---"
grep -A 40 "## Log in to Docker" "$FILE" | head -45
echo "---"
echo ""
echo "Next steps:"
echo "  git diff $FILE"
echo "  git add $FILE"
echo "  git commit -m 'docs: add sbx login and network policy selection to Lab 5'"
echo "  git push"
