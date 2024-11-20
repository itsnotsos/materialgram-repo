#!/bin/bash

VERSION_FILE="version"

SPEC_FILE="materialgram.spec"

LATEST_TAG=$(curl -s https://api.github.com/repos/kukuruzka165/materialgram/releases/latest | grep -oP '"tag_name":\s*"\K(v?[\d.]+)')

LATEST_VERSION=${LATEST_TAG#v}

if [[ -f "$VERSION_FILE" ]]; then
  SAVED_VERSION=$(<"$VERSION_FILE")
else
  SAVED_VERSION=""
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
  git add materialgram.spec version
  git commit -m "Update to $LATEST_VERSION"
else
  echo "No changes to commit."
fi
