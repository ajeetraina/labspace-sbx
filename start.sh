#!/bin/bash
set -e

TTYD_PORT=8085
FIFO_PATH=/tmp/labspace-cmd.fifo

if ! command -v ttyd &>/dev/null; then
  echo "ERROR: ttyd not found. Install with: brew install ttyd"
  exit 1
fi

if ! command -v sbx &>/dev/null; then
  echo "ERROR: sbx not found. Install with: brew install docker/tap/sbx"
  exit 1
fi

# Kill anything on port 8085
echo "==> Clearing port $TTYD_PORT..."
lsof -ti tcp:$TTYD_PORT | xargs kill -9 2>/dev/null || true
sleep 1

# Create FIFO for receiving commands from the Run button
rm -f $FIFO_PATH
mkfifo $FIFO_PATH
echo "==> Created command FIFO at $FIFO_PATH"

# Start ttyd with a zsh that also reads from the FIFO
echo "==> Starting ttyd on port $TTYD_PORT..."
ttyd -p $TTYD_PORT --writable \
  bash -c "exec > /dev/tty; tail -f $FIFO_PATH | zsh &  exec zsh" &
TTYD_PID=$!
sleep 1

if ! lsof -ti tcp:$TTYD_PORT &>/dev/null; then
  echo "ERROR: ttyd failed to start"
  exit 1
fi
echo "    ttyd running (PID: $TTYD_PID)"

echo "==> Starting Labspace..."
CONTENT_PATH=$PWD docker compose up &
COMPOSE_PID=$!

echo ""
echo "✅ Labspace ready at http://localhost:3030"
echo "   Left  → sbx lab instructions"
echo "   Right → your Mac terminal"
echo ""
echo "Press Ctrl+C to stop"

trap "echo 'Stopping...'; kill $TTYD_PID 2>/dev/null; CONTENT_PATH=$PWD docker compose down; rm -f $FIFO_PATH" EXIT
wait $COMPOSE_PID
