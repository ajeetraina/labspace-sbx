#!/bin/bash
# start.sh - Launch the sbx Labspace with Mac terminal in browser

set -e

TTYD_PORT=8085

# Check prerequisites
if ! command -v ttyd &>/dev/null; then
  echo "ERROR: ttyd not found. Install with: brew install ttyd"
  exit 1
fi

if ! command -v sbx &>/dev/null; then
  echo "ERROR: sbx not found. Install with: brew install docker/tap/sbx"
  exit 1
fi

# Kill anything already on port 8085
echo "==> Checking port $TTYD_PORT..."
lsof -ti tcp:$TTYD_PORT | xargs kill -9 2>/dev/null && echo "    Cleared stale process on port $TTYD_PORT" || true
sleep 1

echo "==> Starting ttyd (Mac terminal in browser) on port $TTYD_PORT..."
ttyd -p $TTYD_PORT --writable zsh &
TTYD_PID=$!
sleep 1

# Verify ttyd actually started
if ! lsof -ti tcp:$TTYD_PORT &>/dev/null; then
  echo "ERROR: ttyd failed to start on port $TTYD_PORT"
  exit 1
fi
echo "    ttyd running (PID: $TTYD_PID)"

echo "==> Starting Labspace..."
CONTENT_PATH=$PWD docker compose up &
COMPOSE_PID=$!

echo ""
echo "✅ Labspace is starting!"
echo "   Open http://localhost:3030 in your browser"
echo "   Left panel  → sbx lab instructions"
echo "   Right panel → your Mac terminal (sbx is ready to use)"
echo ""
echo "   Press Ctrl+C to stop everything"
echo ""

trap "echo 'Stopping...'; kill $TTYD_PID 2>/dev/null; CONTENT_PATH=$PWD docker compose down" EXIT
wait $COMPOSE_PID
