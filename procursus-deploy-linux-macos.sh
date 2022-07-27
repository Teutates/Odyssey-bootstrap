#!/bin/sh
if [ "$(uname)" = "Darwin" ]; then
	if [ "$(uname -p)" = "arm" ] || [ "$(uname -p)" = "arm64" ]; then
		if [ "$(SYSTEM_VERSION_COMPAT=1 sw_vers -productName)" != "Mac OS X" ]; then
			echo "It's recommended that this script be ran on macOS/Linux with a non-bootstrapped iOS device running checkra1n attached."
			echo "Press enter to continue"
			read -r REPLY
			ARM=yes
		fi
	fi
fi

CURRENTDIR=$(pwd)
ODYSSEYDIR=$(mktemp -d)

cat << "EOF"
Odysseyra1n Installation Script
Copyright (C) 2022, CoolStar. All Rights Reserved

Before you begin:
If you're currently jailbroken with a different bootstrap
installed, you will need to Reset System via the Loader app
before running this script.

Press enter to continue.
EOF
read -r REPLY

if ! which curl > /dev/null; then
	echo "Error: cURL not found."
	exit 1
fi
if [ "${ARM}" != yes ]; then
	if ! which iproxy > /dev/null; then
		echo "Error: iproxy not found."
		exit 1
	fi
fi

cp bootstrap-ssh.tar.gz $ODYSSEYDIR

cd "$ODYSSEYDIR"

echo '#!/bin/bash' > odysseyra1n-install.bash
if [ ! "${ARM}" = yes ]; then
	echo 'cd /var/root' >> odysseyra1n-install.bash
fi
cat << "EOF" >> odysseyra1n-install.bash
if [[ -f "/.bootstrapped" ]]; then
    echo "Error: Migration from other bootstraps is no longer supported."
    rm ./bootstrap* ./*.deb odysseyra1n-install.bash
    exit 1
fi
if [[ -f "/.installed_odyssey" ]]; then
        echo "Error: Odysseyra1n is already installed."
        rm ./bootstrap* ./*.deb odysseyra1n-install.bash
        exit 1
fi

mount -o rw,union,update /dev/disk0s1s7
#rm -rf /etc/{alternatives,apt,ssl,ssh,dpkg,profile{,.d}} /Library/dpkg /var/{cache,lib}
mkdir -p /private/preboot/procursus
rm -rf /private/var/jb
ln -s /private/preboot/procursus /private/var/jb
gzip -d bootstrap-ssh.tar.gz
tar --preserve-permissions -xkf bootstrap-ssh.tar -C /

export PATH=/var/jb/usr/local/sbin:/var/jb/usr/local/bin:/var/jb/usr/sbin:/var/jb/usr/bin:/var/jb/sbin:/var/jb/bin:/var/jb/usr/bin/X11:/var/jb/usr/games

/var/jb/prep_bootstrap.sh
echo "(4) Installing Sileo and upgrading Procursus packages..."
#dpkg -i org.coolstar.sileo_2.3_iphoneos-arm.deb > /dev/null
#uicache -p /Applications/Sileo.app
#mkdir -p /var/jb/etc/apt/sources.list.d /var/jb/etc/apt/preferences.d
#{
#    echo "Types: deb"
#    echo "URIs: https://repo.theodyssey.dev/"
#    echo "Suites: ./"
#    echo "Components: "
#    echo ""
#} > /etc/apt/sources.list.d/odyssey.sources
touch /var/jb/var/lib/dpkg/available
#touch /.mount_rw
touch /var/jb/.installed_odyssey
#apt-get update -o Acquire::AllowInsecureRepositories=true
#apt-get dist-upgrade -y --allow-downgrades --allow-unauthenticated
#uicache -p /var/binpack/Applications/loader.app
rm ./bootstrap* ./*.deb odysseyra1n-install.bash
echo "Done!"
EOF

echo "(1) Downloading resources..."
IPROXY=$(iproxy 28605 44 >/dev/null 2>&1 & echo $!)
#curl -sLOOOOO https://github.com/coolstar/Odyssey-bootstrap/raw/master/bootstrap_1500.tar.gz \
#	https://github.com/coolstar/Odyssey-bootstrap/raw/master/bootstrap_1600.tar.gz \
#	https://github.com/coolstar/Odyssey-bootstrap/raw/master/bootstrap_1700.tar.gz \
#	https://github.com/coolstar/Odyssey-bootstrap/raw/master/org.coolstar.sileo_2.3_iphoneos-arm.deb \
#	https://github.com/coolstar/Odyssey-bootstrap/raw/master/org.swift.libswift_5.0-electra2_iphoneos-arm.deb
if [ ! "${ARM}" = yes ]; then
	echo "(2) Copying resources to your device..."
	echo "Default password is: alpine"
	scp -qP28605 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" bootstrap-ssh.tar.gz \
		odysseyra1n-install.bash \
		root@127.0.0.1:/var/root/
fi
echo "(3) Bootstrapping your device..."
if [ "${ARM}" = yes ]; then
	bash odysseyra1n-install.bash
else
	echo "Default password is: alpine"
	ssh -qp28605 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" root@127.0.0.1 "bash /var/root/odysseyra1n-install.bash"
	kill "$IPROXY"
	cd "$CURRENTDIR"
	rm -rf "$ODYSSEYDIR"
fi
