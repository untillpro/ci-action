#!/usr/bin/env bash
set -Eeuo pipefail

# Node.js language-specific CI logic, extracted from ci_main.sh

echo "::group::Build"
npm install
npm run build --if-present
npm test
echo "::endgroup::"
