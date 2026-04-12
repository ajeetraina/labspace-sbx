#!/bin/bash
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

echo "==> Starting ttyd on port $TTYD_PORT..."
ttyd -p $TTYD_PORT --writable zsh &
TTYD_PID=$!
sleep 1

if ! lsof -ti tcp:$TTYD_PORT &>/dev/null; then
  echo "ERROR: ttyd failed to start"
  exit 1
fi
echo "    ttyd running (PID: $TTYD_PID)"

echo "==> Starting Labspace..."
docker compose \
  -f oci://dockersamples/labspace \
  -f compose.override.yaml \
  up &
COMPOSE_PID=$!

echo ""
echo "✅ Labspace ready at http://localhost:3030"
echo "   Left  → sbx lab instructions"
echo "   Right → your Mac terminal (sbx ready)"
echo ""
echo "Press Ctrl+C to stop"

trap "echo 'Stopping...'; kill $TTYD_PID 2>/dev/null; docker compose -f oci://dockersamples/labspace -f compose.override.yaml down" EXIT
wait $COMPOSE_PID
