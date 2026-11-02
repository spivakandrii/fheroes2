#!/bin/bash
# Downloads the free HoMM2 demo with fheroes2's own script and copies it to the iPad data folder.
# Usage: install_demo.sh [ip]
set -e
IP=${1:-192.168.1.130}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DEST=~/fh2deps/demodata

command -v unzip > /dev/null || { echo "unzip is required"; exit 1; }
mkdir -p $DEST
# The checkout may have CRLF line endings on Windows.
[ -d $DEST/data ] || bash <(sed 's/\r$//' $ROOT/script/demo/download_demo_version.sh) $DEST

export SSH_ASKPASS=~/sshpw.sh SSH_ASKPASS_REQUIRE=force DISPLAY=:0
OPTS="-o ConnectTimeout=10 -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa,ssh-dss -o PubkeyAcceptedAlgorithms=+ssh-rsa"
ssh $OPTS root@$IP "mkdir -p /var/mobile/Media/fheroes2"
scp -r $OPTS $DEST/data $DEST/maps root@$IP:/var/mobile/Media/fheroes2/
ssh $OPTS root@$IP "chown -R mobile:mobile /var/mobile/Media/fheroes2 && ls -la /var/mobile/Media/fheroes2/data"
