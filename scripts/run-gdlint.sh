#!/bin/bash
# Run gdlint with project config

cd "$(git rev-parse --show-toplevel)"
exec /home/openclaw/.local/bin/gdlint "$@"
