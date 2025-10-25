#!/bin/sh
set -e
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

minimum_systemd_version=257
actual_systemd_version=$(/lib/systemd/systemd --version | head -n1 | cut -d' ' -f 2)
if [[ $actual_systemd_version -lt $minimum_systemd_version ]]; then
  echo Error: systemd version $systemd_version is too old. The installer requires at least $minimum_systemd_version.
  exit 1
fi
echo Systemd version: $actual_systemd_version
if [[ ! -f /bin/portablectl ]]; then
  echo Error: /bin/portablectl not present, you may need to install systemd-portable
  exit 1
fi
if [[ ! -f /lib/systemd/systemd-sysupdate ]]; then
  echo Error: /lib/systemd/systemd-sysupdate not present, you may need to install experimental systemd features
  exit 1
fi
if [[ ! -d /var/lib/portables ]]; then
  echo Error: /var/lib/portables directory does not exist
  exit 1
fi
filesystem=$(stat -f -c %T /var/lib/portables)
if [[ "$filesystem" != btrfs ]]; then
  echo Installing onto any filesystem other than btrfs is currently untested.
  exit 1
fi

echo Elevating privileges via run0
run0 sh <<EOF
  set -e
  echo Creating directory /etc/sysupdate.collectrack.d/
  mkdir -vp /etc/sysupdate.collectrack.d/
  echo Installing /etc/sysupdate.collectrack.d/portable.target
  curl --fail-with-body -L -o /etc/sysupdate.collectrack.d/portable.transfer https://raw.githubusercontent.com/LevitatingBusinessMan/collectrack/refs/heads/master/systemd/portable.transfer
  echo Updating collectrack component via systemd-sysupdate
  /lib/systemd/systemd-sysupdate -C collectrack update
EOF

echo -e Collectrack portable installation complete
echo -e To update collectrack, run ${GREEN}/lib/systemd/systemd-sysupdate -C collectrack update${NC}
echo -e View installed portables with ${GREEN}portablectl list${NC}
echo -e Collectrack may be started with ${GREEN}portablectl attach --now collectrack${NC}
echo -e To uninstall, remove ${RED}/etc/sysupdate.collectrack.d/${NC} and installed portables
