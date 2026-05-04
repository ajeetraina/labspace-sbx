#!/usr/bin/env bash
# Convenience helper for the Blast Radius Test lab.
# Sets up the ~/precious/ directory with sample files. Re-runnable.
set -e
mkdir -p ~/precious
echo "Q4 forecast: confidential"  > ~/precious/forecast.txt
echo "DB_PASSWORD=do-not-leak"    > ~/precious/credentials.env
echo "// proprietary algorithm"   > ~/precious/source.code
echo "Set up ~/precious/ with 3 sample files:"
ls -la ~/precious/
