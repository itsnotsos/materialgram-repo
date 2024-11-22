#!/bin/bash

set -e

REPO="kukuruzka165/materialgram"

LATEST_RELEASE=$(curl -s https://api.github.com/repos/${REPO}/releases/latest)
LATEST_TAG=$(echo "$LATEST_RELEASE" | grep -oP '"tag_name":\s*"\K(v?[\d.]+)')

mkdir -p ~/rpmbuild/{SPECS,SOURCES,RPMS/$(arch)}
cp *.spec ~/rpmbuild/SPECS/
cd $GITHUB_WORKSPACE

echo "Downloading the latest release tarball..."
DOWNLOAD_URL=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" \
  | jq -r '.assets[] | select(.name | endswith(".tar.gz")) | .browser_download_url')

curl -L "$DOWNLOAD_URL" -o ~/rpmbuild/SOURCES/materialgram-latest.tar.gz
tar -xzf ~/rpmbuild/SOURCES/materialgram-latest.tar.gz -C ~/rpmbuild/SOURCES
rm -rf ~/rpmbuild/SOURCES/materialgram-latest.tar.gz

echo "Building the RPM..."
rpmbuild -ba ~/rpmbuild/SPECS/*.spec

echo "Organizing RPM files..."
mkdir -p "$GITHUB_WORKSPACE/repo/rpms/x86_64"
mv ~/rpmbuild/RPMS/$(arch)/*.rpm "$GITHUB_WORKSPACE/repo/rpms/x86_64/"
rpm_count=$(ls "$GITHUB_WORKSPACE/repo/rpms/x86_64/"*.rpm | wc -l)

if [ "$rpm_count" -gt 1 ]; then
  echo "More than one RPM file found, performing cleanup."
  latest_rpm=$(ls "$GITHUB_WORKSPACE/repo/rpms/x86_64/"*.rpm | sort -V | tail -n 1)
  for rpm in "$GITHUB_WORKSPACE/repo/rpms/x86_64/"*.rpm; do
    if [[ "$rpm" != "$latest_rpm" ]]; then
      rm -v "$rpm"
    fi
  done
else
  echo "Less than two RPMs found, skipping cleanup..."
fi

echo "Updating repository metadata..."
cd "$GITHUB_WORKSPACE/repo/rpms"
rm -rf repodata
createrepo --update .
cd ..
echo "Adding and committing changes to git..."
git config --global user.name "itsnotsos"
git config --global user.email "179767921+itsnotsos@users.noreply.github.com"
git add rpms
git commit -m "Updated to ${LATEST_TAG}"
git push
