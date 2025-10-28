#!/bin/bash

set -e

CURR_DIR=$(cd "$(dirname "$0")" && pwd)

cd "$CURR_DIR"/../antares_web/webapp

npm run build -- --mode=desktop

cp -r dist/ ../../resources/webapp
rm -rf dist/