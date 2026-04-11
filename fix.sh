#!/bin/bash
set -e
[ ! -f "labspace/04-secrets.md" ] && echo "ERROR: Run from repo root" && exit 1
python3 - << 'EOF'
from pathlib import Path
f = Path("labspace/04-secrets.md")
t = f.read_text()

old = '''| Service | Environment variable(s) injected |
|---|---|
| `openai` | `OPENAI_API_KEY` |
| `anthropic` | `ANTHROPIC_API_KEY` |
| `github` | `GH_TOKEN`, `GITHUB_TOKEN` |
| `google` | `GEMINI_API_KEY`, `GOOGLE_API_KEY` |
| `aws` | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` |'''

new = '''| Service | Environment variable injected |
|---------|-------------------------------|
| openai | `OPENAI_API_KEY` |
| anthropic | `ANTHROPIC_API_KEY` |
| github | `GH_TOKEN`, `GITHUB_TOKEN` |
| google | `GEMINI_API_KEY`, `GOOGLE_API_KEY` |
| aws | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` |'''

if old not in t:
    print("ERROR: target not found")
    exit(1)
f.write_text(t.replace(old, new))
print("Done ✅")
EOF
