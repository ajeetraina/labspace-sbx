#!/bin/bash
# start.sh - Launch the sbx Labspace
#
# Prerequisites:
#   brew install ttyd
#   brew install docker/tap/sbx

set -e

TTYD_PORT=8085

if ! command -v ttyd &>/dev/null; then
  echo "ERROR: ttyd not found. Install with: brew install ttyd"
  exit 1
fi

if ! command -v sbx &>/dev/null; then
  echo "ERROR: sbx not found. Install with: brew install docker/tap/sbx"
  exit 1
fi

echo "==> Clearing port $TTYD_PORT..."
lsof -ti tcp:$TTYD_PORT | xargs kill -9 2>/dev/null || true
sleep 1

echo "==> Starting terminal on port $TTYD_PORT..."
ttyd -p $TTYD_PORT --writable zsh &
TTYD_PID=$!
sleep 1

if ! lsof -ti tcp:$TTYD_PORT &>/dev/null; then
  echo "ERROR: ttyd failed to start on port $TTYD_PORT"
  exit 1
fi
echo "    ttyd PID: $TTYD_PID"

echo "==> Starting Labspace..."
docker compose \
  -f oci://dockersamples/labspace \
  -f compose.override.yaml \
  up &
COMPOSE_PID=$!

echo ""
echo "==========================================="
echo "  Labspace ready at http://localhost:3030"
echo "  Term 1 / Term 2 → your Mac terminal"
echo "  Run: sbx ls, sbx version, etc."
echo "==========================================="
echo ""
echo "Press Ctrl+C to stop"

cleanup() {
  echo "Stopping..."
  kill $TTYD_PID 2>/dev/null || true
  docker compose \
    -f oci://dockersamples/labspace \
    -f compose.override.yaml \
    down 2>/dev/null || true
}
trap cleanup EXIT
wait $COMPOSE_PID
