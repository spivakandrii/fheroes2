#!/bin/bash
# Installs the built .deb on the iPad and resprings. Usage: deploy.sh [ip]
set -e
IP=${1:-192.168.1.130}
DEB=~/fh2deps/packages/fheroes2-ios5.deb

[ -x ~/sshpw.sh ] || { printf '#!/bin/bash\necho alpine\n' > ~/sshpw.sh; chmod +x ~/sshpw.sh; }
export SSH_ASKPASS=~/sshpw.sh SSH_ASKPASS_REQUIRE=force DISPLAY=:0
OPTS="-o ConnectTimeout=10 -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa,ssh-dss -o PubkeyAcceptedAlgorithms=+ssh-rsa"

scp $OPTS $DEB root@$IP:/tmp/fheroes2.deb
# SpringBoard caches app icons: drop ours and rescan apps, otherwise a changed icon is not shown.
ssh $OPTS root@$IP "killall fheroes2_bin 2>/dev/null; dpkg -r org.fheroes2.ios5 >/dev/null 2>&1; dpkg -i /tmp/fheroes2.deb && mkdir -p /var/mobile/Media/fheroes2 && chown -R mobile:mobile /var/mobile/Media/fheroes2 && rm -f /var/mobile/Library/Caches/com.apple.IconsCache/org.fheroes2* && su mobile -c uicache; killall SpringBoard 2>/dev/null; true"
