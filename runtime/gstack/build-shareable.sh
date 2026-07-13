#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd -P)"
cd "$ROOT"

if ! command -v bun >/dev/null 2>&1; then
  echo "Bun is required to build the browser and document helpers." >&2
  exit 1
fi

bun install --frozen-lockfile
mkdir -p extension/lib browse/dist design/dist make-pdf/dist
cp node_modules/xterm/lib/xterm.js extension/lib/xterm.js
cp node_modules/xterm/css/xterm.css extension/lib/xterm.css
cp node_modules/xterm-addon-fit/lib/xterm-addon-fit.js extension/lib/xterm-addon-fit.js

bun build --compile browse/src/cli.ts --outfile browse/dist/browse
bun build --compile browse/src/find-browse.ts --outfile browse/dist/find-browse
bun build --compile design/src/cli.ts --outfile design/dist/design
bun build --compile make-pdf/src/cli.ts --outfile make-pdf/dist/pdf
bun build --compile bin/gstack-global-discover.ts --outfile bin/gstack-global-discover
bash browse/scripts/build-node-server.sh

chmod +x browse/dist/browse browse/dist/find-browse design/dist/design make-pdf/dist/pdf bin/gstack-global-discover
echo "Skillshare runtime helpers built successfully."
