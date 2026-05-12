#!/usr/bin/env sh
set -eu

MANIFEST_FILE="net.imput.helium.yml"
METADATA_FILE="net.imput.helium.metainfo.xml"
REPO_URL="https://github.com/imputnet/helium-linux/releases/download"

if [ -f "fetch.config.yml" ]; then
    ALLOW_PRERELEASE=$(grep 'allow-prerelease:' fetch.config.yml | head -1 | awk '{print $2}')
else
    ALLOW_PRERELEASE="false"
fi

if [ "$ALLOW_PRERELEASE" = "true" ]; then
    FILTER="true"
else
    FILTER=".prerelease == false"
fi

printf "   Fetching releases from GitHub...\n"
RELEASES_JSON=$(curl -s https://api.github.com/repos/imputnet/helium-linux/releases |
    jq -c "[.[] | select(.tag_name != null and ($FILTER))] | sort_by(.created_at) | last")
LATEST_VERSION=$(printf "%s" "$RELEASES_JSON" | jq -r '.tag_name')
IS_PRERELEASE=$(printf "%s" "$RELEASES_JSON" | jq -r '.prerelease')

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" = "null" ]; then
    printf "   Error: Failed to fetch valid version tag from GitHub.\n"
    exit 1
fi

CURRENT_VERSION=$(grep 'helium-[0-9]' "$MANIFEST_FILE" | head -1 | sed 's/.*helium-\([0-9.]*\).*/\1/')
CURRENT_DATE=$(date '+%Y-%m-%d')

printf "version: %s\nprerelease: %s\n" "$LATEST_VERSION" "$IS_PRERELEASE" > version.txt

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    printf "   Manifest is already up to date (%s).\n" "$CURRENT_VERSION"
    # We exit successfully; the workflow will see no git diff and stop.
    exit 0
fi

printf "   Updating manifest from %s -> %s\n" "$CURRENT_VERSION" "$LATEST_VERSION"

# Update Manifest Files
sed "s|helium-linux/releases/download/${CURRENT_VERSION}|helium-linux/releases/download/${LATEST_VERSION}|g" "$MANIFEST_FILE" > "_" && mv "_" "$MANIFEST_FILE"
sed "s|helium-${CURRENT_VERSION}-x86_64_linux|helium-${LATEST_VERSION}-x86_64_linux|g" "$MANIFEST_FILE" > "_" && mv "_" "$MANIFEST_FILE"
sed "s|helium-${CURRENT_VERSION}-arm64_linux|helium-${LATEST_VERSION}-arm64_linux|g" "$MANIFEST_FILE" > "_" && mv "_" "$MANIFEST_FILE"

sed "s|version=\"${CURRENT_VERSION}\"|version=\"${LATEST_VERSION}\"|g" "$METADATA_FILE" > "_" && mv "_" "$METADATA_FILE"
sed "s|date=\"[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\"|date=\"${CURRENT_DATE}\"|g" "$METADATA_FILE" > "_" && mv "_" "$METADATA_FILE"

# Update the version tracker
printf "version: %s\nprerelease: %s\n" "$LATEST_VERSION" "$IS_PRERELEASE" > version.txt

printf "   Downloading binaries to compute SHA256...\n"

DL_X86="$REPO_URL/$LATEST_VERSION/helium-$LATEST_VERSION-x86_64_linux.tar.xz"
TMP_X86=$(mktemp)
curl -L -s -o "$TMP_X86" "$DL_X86"
NEW_SHA256_X86=$(sha256sum "$TMP_X86" | awk '{print $1}')
rm -f "$TMP_X86"

DL_ARM="$REPO_URL/$LATEST_VERSION/helium-$LATEST_VERSION-arm64_linux.tar.xz"
TMP_ARM=$(mktemp)
curl -L -s -o "$TMP_ARM" "$DL_ARM"
NEW_SHA256_ARM=$(sha256sum "$TMP_ARM" | awk '{print $1}')
rm -f "$TMP_ARM"

if [ -z "$NEW_SHA256_X86" ] || [ -z "$NEW_SHA256_ARM" ]; then
    printf "   Failed to compute SHA256 checksums.\n"
    exit 1
fi

printf "   New x86_64 SHA256: %s\n   New aarch64 SHA256: %s\n" "$NEW_SHA256_X86" "$NEW_SHA256_ARM"

# This finds the URL line for each architecture, moves to the next line (n), and replaces the hash.
sed "/x86_64_linux\.tar\.xz/{n;s/sha256: [a-f0-9]*/sha256: $NEW_SHA256_X86/;}" "$MANIFEST_FILE" > "_" && mv "_" "$MANIFEST_FILE"
sed "/arm64_linux\.tar\.xz/{n;s/sha256: [a-f0-9]*/sha256: $NEW_SHA256_ARM/;}" "$MANIFEST_FILE" > "_" && mv "_" "$MANIFEST_FILE"

printf "   Manifest updated successfully.\n"

printf "   Done.\n"
