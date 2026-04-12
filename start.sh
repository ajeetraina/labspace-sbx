#!/bin/bash
# start.sh - Launch the sbx Labspace with Mac terminal in browser
#
# Prerequisites:
#   brew install ttyd
#   brew install docker/tap/sbx

set -e

TTYD_PORT=8085

# Check ttyd is installed
if ! command -v ttyd &>/dev/null; then
  echo "ERROR: ttyd not found. Install with: brew install ttyd"
  exit 1
fi

# Check sbx is installed
if ! command -v sbx &>/dev/null; then
  echo "ERROR: sbx not found. Install with: brew install docker/tap/sbx"
  exit 1
fi

echo "==> Starting ttyd (Mac terminal in browser) on port $TTYD_PORT..."
ttyd -p $TTYD_PORT --writable zsh &
TTYD_PID=$!
echo "    ttyd PID: $TTYD_PID"

# Give ttyd a moment to bind the port
sleep 1

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

# Wait and clean up on exit
trap "echo 'Stopping...'; kill $TTYD_PID $COMPOSE_PID 2>/dev/null; docker compose down" EXIT
wait $COMPOSE_PID
