#!/bin/bash

set -e

CURR_DIR=$(cd "$(dirname "$0")" && pwd)

cd "$CURR_DIR"/../antares_web/webapp

npm run build -- --mode=desktop

cd ..
cp -r antares_web/webapp/dist/ resources/webapp
