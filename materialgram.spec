Name:           materialgram
Version:        5.8.1.1
Release:        3%{?dist}
Summary:        Telegram Desktop fork with material icons and some improvements
Vendor:         burhancodes
Group:          Applications/Internet
Packager:       Burhanverse  <burhanverse@proton.me>
License:        GPLv3
URL:            https://github.com/kukuruzka165/materialgram

%description
Telegram Desktop fork with Material Design and other improvements, which is based on the Telegram API and the MTProto secure protocol.

Author: kukuruzka  <kukuruzka165@github.com>

%prep
cd %{_sourcedir}/

%build

%install
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/applications
mkdir -p %{buildroot}/usr/share/dbus-1
mkdir -p %{buildroot}/usr/share/icons
mkdir -p %{buildroot}/usr/share/metainfo

cp -a %{_sourcedir}/usr/bin/materialgram %{buildroot}/usr/bin/

cp -a %{_sourcedir}/usr/share/* %{buildroot}/usr/share/

%files
/usr/bin/materialgram
%dir /usr/share/applications
/usr/share/applications/*
%dir /usr/share/dbus-1
/usr/share/dbus-1/*
%dir /usr/share/icons
/usr/share/icons/*
%dir /usr/share/metainfo
/usr/share/metainfo/*

%preun
  pkill -f '/usr/bin/materialgram' || true

%postun
if [ "$1" -eq 0 ]; then
  # Determine the home directory
  USER_HOME="/home/${SUDO_USER:-$USER}"

  # Remove user-specific data only on full uninstall
  if [ -d "$USER_HOME/.local/share/materialgram" ]; then
    rm -rf "$USER_HOME/.local/share/materialgram"
  fi
fi
