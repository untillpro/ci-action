#!/usr/bin/env bash

# Node.js language-specific CI logic, extracted from ci_main.sh

echo "Node.js project detected"

echo "::group::Build"
npm install
npm run build --if-present
npm test

# Run codecov if token provided
if [ -n "$CODECOV_TOKEN" ]; then
    echo "::endgroup::"
    echo "::group::Codecov"
    npm install -g codecov
    istanbul cover ./node_modules/mocha/bin/_mocha --reporter lcovonly -- -R spec
    codecov --token="$CODECOV_TOKEN"
fi

echo "::endgroup::"

