#!/bin/bash

VERSION_FILE="version"
SPEC_FILE="materialgram.spec"

LATEST_RELEASE=$(curl -s https://api.github.com/repos/kukuruzka165/materialgram/releases/latest)

LATEST_TAG=$(echo "$LATEST_RELEASE" | grep -oP '"tag_name":\s*"\K(v?[\d.]+)')

LATEST_VERSION=${LATEST_TAG#v}

if [[ -f "$VERSION_FILE" ]]; then
  SAVED_VERSION=$(<"$VERSION_FILE")
else
  SAVED_VERSION=""
fi

EXPECTED_FILE="materialgram-${LATEST_TAG}.tar.gz"

ASSETS=$(echo "$LATEST_RELEASE" | grep -oP '"browser_download_url":\s*"\K[^"]+')

if ! echo "$ASSETS" | grep -q "$EXPECTED_FILE"; then
  echo "Error: The latest release does not contain $EXPECTED_FILE."
  exit 1
fi

if [[ "$LATEST_VERSION" != "$SAVED_VERSION" ]]; then
  echo "New version detected: $LATEST_VERSION (previous: $SAVED_VERSION)"

  sed -i "s/^Version:\s*[0-9.]\+/Version:        $LATEST_VERSION/" "$SPEC_FILE"

  echo "$LATEST_VERSION" > "$VERSION_FILE"

  echo "Updated the version in $SPEC_FILE to $LATEST_VERSION."
else
  echo "No new version detected. Current version is $SAVED_VERSION."
fi

if [ "$(git status --porcelain)" != "" ]; then
  git config --global user.name "Burhanverse"
  git config --global user.email "burhanverse@gmail.com"
  git add "$SPEC_FILE" "$VERSION_FILE"
  git commit -m "Update SPEC to $LATEST_VERSION"
else
  echo "No changes to commit."
fi
