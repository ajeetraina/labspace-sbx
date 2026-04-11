#!/bin/bash
set -e
[ ! -f "labspace/04-secrets.md" ] && echo "ERROR: Run from repo root" && exit 1

python3 - << 'EOF'
from pathlib import Path
f = Path("labspace/04-secrets.md")
t = f.read_text()

old = '''> **If prompted "Secret already exists. Overwrite?"** — delete first, then re-set:
>
> ```bash
> sbx secret delete -g openai
> echo "$OPENAI_API_KEY" | sbx secret set -g openai
> ```'''

new = '''> **If prompted "Secret already exists. Overwrite?"** — use the interactive prompt instead of piping:
>
> ```bash
> sbx secret set -g openai
> # Paste your key when prompted, then type y to overwrite
> ```'''

if old not in t:
    print("ERROR: target not found")
    exit(1)
f.write_text(t.replace(old, new))
print("Done ✅")
EOF
