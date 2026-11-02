#!/bin/bash
# Copies the original game data (DATA, MAPS, MUSIC of an installed HoMM2, e.g. the GOG version) to the iPad,
# replacing the demo. Usage: install_data.sh "/mnt/c/Games/HoMM 2 Gold" [ip]
set -e
SRC=$1
IP=${2:-192.168.1.130}
[ -f "$SRC/DATA/HEROES2.AGG" ] || { echo "HEROES2.AGG not found in $SRC/DATA"; exit 1; }

export SSH_ASKPASS=~/sshpw.sh SSH_ASKPASS_REQUIRE=force DISPLAY=:0
OPTS="-o ConnectTimeout=10 -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa,ssh-dss -o PubkeyAcceptedAlgorithms=+ssh-rsa"
DST=/var/mobile/Media/fheroes2

ssh $OPTS root@$IP "mkdir -p $DST && rm -rf $DST/data $DST/maps $DST/music"
scp -rq $OPTS "$SRC/DATA" root@$IP:$DST/data
scp -rq $OPTS "$SRC/MAPS" root@$IP:$DST/maps
[ -d "$SRC/MUSIC" ] && scp -rq $OPTS "$SRC/MUSIC" root@$IP:$DST/music
# iOS has no du/wc: just show the main data files.
ssh $OPTS root@$IP "chown -R mobile:mobile $DST && ls -la $DST/data/*.AGG"
