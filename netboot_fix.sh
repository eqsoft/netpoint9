#!/bin/bash
#we need to run debian stretch
#db grub-install-efi (or similar) fails if we use not the right version of debian
#so we need to use a snapshot
#http://snapshot.debian.org/archive/debian/20161124T211732Z/
#to comment out use : null command
#:<<'COMMENTEDOUT'
#COMMENTEDOUT

cp /etc/apt/sources.list /etc/apt/sources.list.pxe.bak
trap 'echo "restoring apt sources"; rm /etc/apt/preferences; mv /etc/apt/sources.list.pxe.bak /etc/apt/sources.list;apt update;apt upgrade -y' INT TERM EXIT

cat >/etc/apt/sources.list <<'EOF'
deb  http://snapshot.debian.org/archive/debian/20161124T211732Z/ stretch main non-free contrib
deb-src http://snapshot.debian.org/archive/debian/20161124T211732Z/ stretch main non-free contrib

deb http://snapshot.debian.org/archive/debian-security/20161124T211732Z/ stretch/updates main contrib non-free
deb-src http://snapshot.debian.org/archive/debian-security/20161124T211732Z/ stretch/updates main contrib non-free
EOF

cat >/etc/apt/preferences <<'EOF'
Package: *
Pin: origin "snapshot.debian.org"
Pin-Priority: 1001
EOF
apt-get -o Acquire::Check-Valid-Until=false update
apt upgrade -f -y --allow-downgrades


apt install live-build live-config live-boot whois squashfs-tools git -y
git clone https://github.com/eqsoft/netpoint9
cd netpoint9
cp config.net  auto/config 
cat >auto/config <<'EOF'
#!/bin/sh

set -e

lb config noauto \
	--architecture "i386" \
    --linux-flavours "686-pae" \
    --distribution "stretch" \
	--memtest "none" \
	--binary-images "netboot" \
	--bootappend-live "boot=live noeject debug net.ifnames=0 biosdevname=0 locales=de_DE.UTF-8 keyboard-layouts=de username=npuser xpanel=1 xbrowser=seb2 xbrowseropts=-purgecaches,debug,1 xnoblank=1 netboot=nfs nfsroot=192.168.2.10:/srv/debian-live" \
	--debootstrap-options "--variant=minbase" \
	--archive-areas "main contrib non-free" \
	--apt-recommends "false" \
	--apt-indices "false" \
	"${@}"
EOF
#change default webpage
sed -i "/lockPref(\"browser.startup.homepage\",\"/c\lockPref(\"browser.startup.homepage\",\"http://192.168.2.10/\");" ./config/includes.chroot/etc/firefox-esr/firefox-esr.js
sed -i "/\"startURL\":\"/c\"startURL\":\"http://192.168.2.10\"," ./config/includes.chroot/etc/seb2/config.json
#set timeout to 0.1 sec
sed -i "/timeout /c\timeout 1" ./config/bootloaders/pxelinux/pxelinux.cfg/default

#now building the tar file
./build.sh
mkdir /srv
tar xf live-image-i386.netboot.tar -C /srv


#restoring to new debian version
echo "restoring apt sources"; rm /etc/apt/preferences;mv /etc/apt/sources.list.pxe.bak /etc/apt/sources.list;apt update;apt upgrade -y
