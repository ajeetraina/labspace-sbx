#!/bin/bash
# This script disables the run button 

if [ ! -d "labspace" ]; then
  echo "ERROR: Run from root of labspace-sbx"
  exit 1
fi

echo "==> Patching markdown files..."

for f in labspace/*.md; do
  [ -f "$f" ] || continue
  perl -i -pe '
    s/^```bash\s*$/```bash no-run-button\n/g;
    s/^```sh\s*$/```sh no-run-button\n/g;
    s/^```console\s*$/```console no-run-button\n/g;
  ' "$f"
  echo "  ✓ $f"
done

echo ""
echo "==> Done. Committing..."
git add labspace/*.md
git commit -m "fix: disable Run button on all code blocks, keep Copy only"
git push origin main
echo "==> Pushed!"
