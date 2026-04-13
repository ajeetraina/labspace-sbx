#!/bin/bash
# disable-run-button.sh


# Adds no-run-button to all bash/sh/console code blocks in labspace markdown files.
# Copy button is kept. Only the Run button is disabled.

set -e

BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; RESET='\033[0m'
log() { echo -e "${CYAN}==>${RESET} ${BOLD}$1${RESET}"; }
ok()  { echo -e "  ${GREEN}✓${RESET} $1"; }

if [ ! -d "labspace" ]; then
  echo "ERROR: Run this script from the root of your labspace-sbx clone."
  exit 1
fi

log "Adding no-run-button to all bash/sh/console code blocks..."

for f in labspace/*.md; do
  [ -f "$f" ] || continue

  # Count matches before
  before=$(grep -cE '^\`\`\`(bash|sh|console)$' "$f" 2>/dev/null || echo 0)

  if [ "$before" -eq 0 ]; then
    ok "$f — no runnable blocks, skipping"
    continue
  fi

  # Replace ```bash, ```sh, ```console (with nothing after) with no-run-button variant
  # Use perl for reliable multiline-safe in-place replacement on macOS
  perl -i -pe '
    s/^```bash$/```bash no-run-button/g;
    s/^```sh$/```sh no-run-button/g;
    s/^```console$/```console no-run-button/g;
  ' "$f"

  # Count matches after (should be 0 plain ones left)
  after=$(grep -cE '^\`\`\`(bash|sh|console)$' "$f" 2>/dev/null || echo 0)
  patched=$(( before - after ))

  ok "$f — patched $patched block(s)"
done

log "Done! Committing changes..."

git add labspace/*.md
git diff --cached --stat

read -p "Commit and push? (y/n) " confirm
if [[ "$confirm" == "y" ]]; then
  git commit -m "fix: disable Run button on all code blocks, keep Copy only"
  git push origin main
  echo -e "\n${GREEN}✓ Pushed to GitHub${RESET}"
else
  echo "Changes staged but not committed. Run 'git commit' when ready."
fi
