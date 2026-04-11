#!/bin/bash
set -e
[ ! -f "labspace/05-network-policy.md" ] && echo "ERROR: Run from repo root" && exit 1
python3 - << 'EOF'
from pathlib import Path
f = Path("labspace/05-network-policy.md")
t = f.read_text()

old = '''Leave this running. Now go to your sandbox session and ask Codex to do something that requires network access:

```
Run pip install requests and tell me the version installed.
```

Watch the policy log. You'll see:

```
ALLOWED   files.pythonhosted.org   200
ALLOWED   pypi.org                 200
```

Every connection — allowed or blocked — is logged with a timestamp.'''

new = '''Leave this running. Now go to your sandbox session and ask Codex to do something that requires network access:

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
- Every connection logged with sandbox name, host, proxy type, rule, timestamp, and hit count'''

if old not in t:
    print("ERROR: target not found")
    exit(1)
f.write_text(t.replace(old, new))

# Also add proxy type explanation to audit trail section
t2 = f.read_text()
old2 = "- **When** each connection happened\n\nFor regulated enterprises"
new2 = """- **When** each connection happened
- **How** it was proxied (`forward` = credential injection active, `forward-bypass` = no injection needed, `transparent` = passthrough)

For regulated enterprises"""
f.write_text(t2.replace(old2, new2))
print("Done ✅")
EOF
