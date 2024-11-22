#!/bin/bash

set -e

VERSION_FILE="version"
SPEC_FILE="materialgram.spec"
REPO="kukuruzka165/materialgram"
WORKSPACE="${GITHUB_WORKSPACE:-$(pwd)}"

LATEST_RELEASE=$(curl -s https://api.github.com/repos/${REPO}/releases/latest)
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
  exit 0  # Abort script as there is no new version to process
fi

echo "Proceeding with RPM build process..."

if [[ "$(git status --porcelain)" != "" ]]; then
  git add "$SPEC_FILE" "$VERSION_FILE"
else
  echo "No changes to commit."
fi

mkdir -p ~/rpmbuild/{SPECS,SOURCES,RPMS/$(arch)}
cp "$SPEC_FILE" ~/rpmbuild/SPECS/

echo "Downloading the latest release tarball..."
DOWNLOAD_URL=$(echo "$ASSETS" | grep "$EXPECTED_FILE")
curl -L "$DOWNLOAD_URL" -o ~/rpmbuild/SOURCES/"$EXPECTED_FILE"
tar -xzf ~/rpmbuild/SOURCES/"$EXPECTED_FILE" -C ~/rpmbuild/SOURCES
rm -rf ~/rpmbuild/SOURCES/"$EXPECTED_FILE"

echo "Building the RPM..."
rpmbuild -ba ~/rpmbuild/SPECS/*.spec

echo "Organizing RPM files..."
mkdir -p "$WORKSPACE/repo/rpms/x86_64"
mv ~/rpmbuild/RPMS/$(arch)/*.rpm "$WORKSPACE/repo/rpms/x86_64/"

rpm_count=$(ls "$WORKSPACE/repo/rpms/x86_64/"*.rpm | wc -l)
if [ "$rpm_count" -gt 1 ]; then
  echo "More than one RPM file found, performing cleanup."
  latest_rpm=$(ls "$WORKSPACE/repo/rpms/x86_64/"*.rpm | sort -V | tail -n 1)
  for rpm in "$WORKSPACE/repo/rpms/x86_64/"*.rpm; do
    if [[ "$rpm" != "$latest_rpm" ]]; then
      rm -v "$rpm"
    fi
  done
else
  echo "Less than two RPMs found, skipping cleanup..."
fi

echo "Updating repository metadata..."
cd "$WORKSPACE/repo/rpms"
rm -rf repodata
createrepo --update .
cd ..

echo "Adding and committing changes to git..."
git config --global user.name "itsnotsos"
git config --global user.email "179767921+itsnotsos@users.noreply.github.com"
git add rpms
git commit -m "Updated to ${LATEST_VERSION}"
git push
