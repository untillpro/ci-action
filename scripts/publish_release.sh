#!/usr/bin/env bash
# Copyright (c) 2020-present unTill Pro, Ltd. and Contributors
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

set -Eeuo pipefail

ASSET="$1"
TOKEN="$2"
KEEP="${3:-8}"
REPOSITORY_OWNER="$4"
REPOSITORY_NAME="$5"
TARGET_COMMITISH="$6"

# Check if asset exists
if [ ! -e "$ASSET" ]; then
    echo "::error::Asset \"$ASSET\" is not found"
    exit 1
fi

# Check if deployer.url exists
if [ ! -f "deployer.url" ]; then
    echo "::error::File \"deployer.url\" missing"
    exit 1
fi

# Generate version (UTC date-time as yyyyMMdd.HHmmss.SSS)
VERSION=$(date -u +"%Y%m%d.%H%M%S.%3N")
# For systems without %3N support, use alternative
if [[ "$VERSION" == *"%3N"* ]]; then
    VERSION=$(date -u +"%Y%m%d.%H%M%S").$(date -u +"%N" | cut -c1-3)
fi

echo "Version: $VERSION"

# Prepare zip file
ZIP_FILE=""
if [ -d "$ASSET" ]; then
    # Create zip from directory
    ZIP_FILE="${ASSET}.zip"
    (cd "$ASSET" && zip -r "../$ZIP_FILE" .)
elif [ -f "$ASSET" ]; then
    if [[ "$ASSET" == *.zip ]]; then
        ZIP_FILE="$ASSET"
    else
        # Create zip from file
        ZIP_FILE="${ASSET}.zip"
        zip "$ZIP_FILE" "$ASSET"
    fi
fi

echo "Zip file: $ZIP_FILE"

# Set up GitHub CLI authentication
export GH_TOKEN="$TOKEN"

# Create release with tag
echo "Creating release $VERSION..."
RELEASE_OUTPUT=$(gh release create "$VERSION" \
    --repo "$REPOSITORY_OWNER/$REPOSITORY_NAME" \
    --target "$TARGET_COMMITISH" \
    --title "$VERSION" \
    --notes "Automated release $VERSION")

echo "Release created: $RELEASE_OUTPUT"

# Upload asset
echo "Uploading asset $ZIP_FILE..."
gh release upload "$VERSION" "$ZIP_FILE" \
    --repo "$REPOSITORY_OWNER/$REPOSITORY_NAME" \
    --clobber

# Get asset download URL
ASSET_URL=$(gh release view "$VERSION" \
    --repo "$REPOSITORY_OWNER/$REPOSITORY_NAME" \
    --json assets \
    --jq ".assets[] | select(.name == \"$(basename $ZIP_FILE)\") | .url")

BROWSER_DOWNLOAD_URL=$(gh release view "$VERSION" \
    --repo "$REPOSITORY_OWNER/$REPOSITORY_NAME" \
    --json assets \
    --jq ".assets[] | select(.name == \"$(basename $ZIP_FILE)\") | .url" | sed 's|api.github.com/repos|github.com|' | sed 's|/assets/|/releases/download/|')

echo "Asset browser download URL: $BROWSER_DOWNLOAD_URL"

# Create deploy.txt
DEPLOY_TXT=$(mktemp)
echo "$BROWSER_DOWNLOAD_URL" > "$DEPLOY_TXT"
cat "deployer.url" >> "$DEPLOY_TXT"

# Upload deploy.txt
echo "Uploading deploy.txt..."
gh release upload "$VERSION" "$DEPLOY_TXT" \
    --repo "$REPOSITORY_OWNER/$REPOSITORY_NAME" \
    --clobber

rm -f "$DEPLOY_TXT"

# Clean up temporary zip if created
if [ "$ZIP_FILE" != "$ASSET" ] && [ -f "$ZIP_FILE" ]; then
    rm -f "$ZIP_FILE"
fi

# Get release information
RELEASE_ID=$(gh release view "$VERSION" \
    --repo "$REPOSITORY_OWNER/$REPOSITORY_NAME" \
    --json id \
    --jq ".id")

RELEASE_HTML_URL=$(gh release view "$VERSION" \
    --repo "$REPOSITORY_OWNER/$REPOSITORY_NAME" \
    --json url \
    --jq ".url")

# Set outputs for GitHub Actions
if [ -n "$GITHUB_OUTPUT" ]; then
    echo "release_id=$RELEASE_ID" >> "$GITHUB_OUTPUT"
    echo "release_name=$VERSION" >> "$GITHUB_OUTPUT"
    echo "release_html_url=$RELEASE_HTML_URL" >> "$GITHUB_OUTPUT"
    echo "asset_browser_download_url=$BROWSER_DOWNLOAD_URL" >> "$GITHUB_OUTPUT"
fi

# Delete old releases if KEEP is set
if [ "$KEEP" -gt 0 ]; then
    echo "Cleaning up old releases (keeping $KEEP most recent)..."

    # Get all releases with timestamp-based names, sorted by name (descending)
    gh release list \
        --repo "$REPOSITORY_OWNER/$REPOSITORY_NAME" \
        --limit 1000 \
        --json tagName,name \
        --jq '.[] | select(.name | test("^[0-9]{8}\\.[0-9]{6}\\.[0-9]{3}$")) | select(.tagName == .name) | .tagName' \
        | sort -r \
        | tail -n +$((KEEP + 1)) \
        | while read -r old_tag; do
            echo "Deleting release $old_tag"
            gh release delete "$old_tag" \
                --repo "$REPOSITORY_OWNER/$REPOSITORY_NAME" \
                --yes \
                --cleanup-tag || true
        done
fi

echo "Publish completed successfully"
echo "Release ID: $RELEASE_ID"
echo "Release URL: $RELEASE_HTML_URL"
echo "Asset URL: $BROWSER_DOWNLOAD_URL"

