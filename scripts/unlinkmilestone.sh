#!/usr/bin/env bash
set -Eeuo pipefail

# Erase milestone list
gh issue edit ${issue} --milestone "" --repo ${repo}


