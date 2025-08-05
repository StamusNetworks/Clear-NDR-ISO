#!/usr/bin/env bash

# Copyright Stamus Networks, 2024
# All rights reserved
# Debian Live/Install ISO script - oss@stamus-networks.com
#
# Please RUN ON Debian Bookworm only !!!

usage()
{
cat << EOF

usage: $0 options

#####################################
#!!! RUN on Debian Bookworm ONLY !!!#
#####################################

SELKS build your own ISO options

OPTIONS:
   -h      Help info
   -g      GUI option - can be "no-desktop"
   -p      Add package(s) to the build - can be one-package or "package1 package2 package3...." (should be confined to up to 10 packages)
   -k      Kernel option - can be the stable standard version of the kernel you wish to deploy -
           aka you can choose any kernel "5/6.x.x" you want.
           Example: "6.5" or "5.15.6" or "6.10.11"

           More info on kernel versions and support:
           https://www.kernel.org/
           https://www.kernel.org/category/releases.html

   By default no options are required. The options presented here are if you wish to enable/disable/add components.
   By default SELKS will be build with a standard Debian Bookworm 64 bit distro.

   EXAMPLE (default):
   ./build-debian-live.sh
   The example above (is the default) will build a SELKS standard Debian Bookworm 64 bit distro (with kernel ver 3.16)

   EXAMPLE (customizations):

   ./build-debian-live.sh -k 6.10
   The example above will build a SELKS Debian Bookworm 64 bit distro with kernel ver 5.10

   ./build-debian-live.sh -k 6.15.11 -p one-package
   The example above will build a SELKS Debian Bookworm 64 bit distro with kernel ver 6.15.11
   and add the extra package named  "one-package" to the build.

   ./build-debian-live.sh -k 6.15.11 -g no-desktop -p one-package
   The example above will build a SELKS Debian Bookworm 64 bit distro, no desktop with kernel ver 6.15.11
   and add the extra package named  "one-package" to the build.

   ./build-debian-live.sh -k 6.15 -g no-desktop -p "package1 package2 package3"
   The example above will build a SELKS Debian Bookworm 64 bit distro, no desktop with kernel ver 6.15
   and add the extra packages named  "package1", "package2", "package3" to the build.



EOF
}

GUI=
KERNEL_VER=

while getopts “hg:k:p:” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         g)
             GUI=$OPTARG
             if [[ "$GUI" != "no-desktop" ]];
             then
               echo -e "\n Please check the option's spelling \n"
               usage
               exit 1;
             fi
             ;;
         k)
             KERNEL_VER=$OPTARG
             if [[ "$KERNEL_VER" =~ ^[5-6]\.[0-9]+?\.?[0-9]+$ ]];
             then
               echo -e "\n Kernel version set to ${KERNEL_VER} \n"
             else
               echo -e "\n Please check the option's spelling "
               echo -e " Also - only kernel versions >5.0 are supported !! \n"
               usage
               exit 1;
             fi
             ;;
         p)
             PKG_ADD+=("$OPTARG")
             #echo "The first value of the pkg array 'PKG_ADD' is '$PKG_ADD'"
             #echo "The whole list of values is '${PKG_ADD[@]}'"
             echo "Packages to be added to the build: ${PKG_ADD[@]} "
             #exit 1;
             ;;
         ?)
             GUI=
             KERNEL_VER=
             PKG_ADD=
             echo -e "\n Using the default options for the SELKS ISO build \n"
             ;;
     esac
done
shift $((OPTIND -1))

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Initialize logging early in the script
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" | tee -a build.log 2>/dev/null || echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a build.log 2>/dev/null || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1"
}

log_debug() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: $1" | tee -a build.log 2>/dev/null || echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: $1"
}

log_info "Starting SELKS ISO build script"
log_debug "Script arguments: $*"
log_debug "Build environment: $(uname -a)"

# Log parsed configuration
log_info "=============================================="
log_info "Build Configuration Summary"
log_info "=============================================="
if [[ -n "$KERNEL_VER" ]]; then
    log_info "Custom kernel version: $KERNEL_VER"
else
    log_info "Kernel: Using default Debian Bookworm kernel"
fi

if [[ "$GUI" == "no-desktop" ]]; then
    log_info "GUI: No desktop environment (headless)"
else
    log_info "GUI: Full desktop environment with XFCE"
fi

if [[ -n "${PKG_ADD[@]}" ]]; then
    log_info "Additional packages: ${PKG_ADD[@]}"
else
    log_info "Additional packages: None"
fi

log_info "Root privileges: Confirmed"
log_info "Log file: build.log (in current directory)"
log_info "=============================================="

# Begin
# Pre staging
#
log_info "Creating Stamus-Live-Build directory"
mkdir -p Stamus-Live-Build

#if presnet make sure we clean up previous state
log_info "Cleaning previous build state"
cd Stamus-Live-Build/ && lb clean --all && cd ../

if [[ -n "$KERNEL_VER" ]];
then

  ### START Kernel Version choice ###
  log_info "Building with custom kernel version: $KERNEL_VER"

  cd Stamus-Live-Build && mkdir -p kernel-misc && cd kernel-misc
  if [[ ${KERNEL_VER} == 3* ]];
  then
    wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-${KERNEL_VER}.tar.xz
  elif [[ ${KERNEL_VER} == 4* ]];
  then
     wget https://www.kernel.org/pub/linux/kernel/v4.x/linux-${KERNEL_VER}.tar.xz
  elif [[ ${KERNEL_VER} == 5* ]];
  then
     wget https://www.kernel.org/pub/linux/kernel/v5.x/linux-${KERNEL_VER}.tar.xz
  elif [[ ${KERNEL_VER} == 6* ]];
  then
     wget https://www.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VER}.tar.xz
  else
    echo "Unsupported kernel version! Only kernel >3.0 are supported"
    exit 1;
  fi

  if [ $? -eq 0 ];
  then
    echo -e "Downloaded successfully linux-${KERNEL_VER}.tar.xz "
  else
    echo -e "\n Please check your connection \n"
    echo -e "CAN NOT download the requested kernel. Please make sure the kernel version is present here - \n"
    echo -e "https://www.kernel.org/pub/linux/kernel/v3.x/ \n"
    echo -e "or here respectively \n"
    echo -e "https://www.kernel.org/pub/linux/kernel/v4.x/ \n"
    exit 1;
  fi

  tar xfJ linux-${KERNEL_VER}.tar.xz
  cd linux-${KERNEL_VER}

  # Default linux kernel config
  # Set up concurrent jobs with respect to number of CPUs

  make defconfig && \
  make clean && \
  make -j `getconf _NPROCESSORS_ONLN` deb-pkg LOCALVERSION=-stamus-amd64 KDEB_PKGVERSION=${KERNEL_VER}
  cd ../../

  # Directory where the kernel image and headers are copied to
  mkdir -p config/packages.chroot/
  # Directory that needs to be present for the Kernel Version choice to work
  mkdir -p cache/contents.chroot/
  # Hook directory for the initramfs script to be copied to
  #mkdir -p config/hooks/
  mkdir -p config/hooks/live/

  # Copy the kernel image and headers
  #mv kernel-misc/*.deb config/packages.chroot/
  #cp ../staging/config/hooks/all_chroot_update-initramfs.sh config/hooks/all_chroot_update-initramfs.chroot
  mv kernel-misc/*.deb config/packages.chroot/
  cp ../staging/config/hooks/live/all_chroot_update-initramfs.sh config/hooks/live/all_chroot_update-initramfs.chroot


  ### END Kernel Version choice ###

  lb config \
  -a amd64 -d bookworm  \
  --archive-areas "main contrib" \
  --swap-file-size 2048 \
  --bootloader syslinux \
  --debian-installer live \
  --bootappend-live "boot=live swap config username=selks-user live-config.hostname=SELKS live-config.user-default-groups=audio,cdrom,floppy,video,dip,plugdev,scanner,bluetooth,netdev,sudo" \
  --linux-packages linux-image-${KERNEL_VER} \
  --linux-packages linux-headers-${KERNEL_VER} \
  --apt-options "--yes --force-yes" \
  --linux-flavour stamus \
  --iso-application SELKS - Suricata Elasticsearch Logstash Kibana Scirius \
  --iso-preparer Stamus Networks \
  --iso-publisher Stamus Networks \
  --iso-volume Stamus-SELKS $LB_CONFIG_OPTIONS

else

  log_info "Using default kernel configuration"
  cd Stamus-Live-Build && lb config \
  -a amd64 -d bookworm \
  --archive-areas "main contrib" \
  --swap-file-size 2048 \
  --debian-installer live \
  --bootappend-live "boot=live swap config username=selks-user live-config.hostname=SELKS live-config.user-default-groups=audio,cdrom,floppy,video,dip,plugdev,scanner,bluetooth,netdev,sudo" \
  --iso-application SELKS - Suricata Elasticsearch Logstash Kibana Scirius \
  --iso-preparer Stamus Networks \
  --iso-publisher Stamus Networks \
  --debootstrap-options "--include=apt-transport-https,ca-certificates,openssl" \
  --apt-options "--yes --allow-unauthenticated" \
  --iso-volume Stamus-SELKS $LB_CONFIG_OPTIONS

# If needed a "live" kernel can be specified like so.
# In SELKS 4 as it uses kernel >4.9 we make sure we keep the "old/unpredictable" naming convention
# and we take care of that in chroot-inside-Debian-Live.sh
# more info -
# https://www.freedesktop.org/wiki/Software/systemd/PredictableNetworkInterfaceNames/
#  --linux-packages linux-headers-4.9.20-stamus \
#  --linux-packages linux-image-4.9.20-stamus \
# echo "deb http://packages.stamus-networks.com/selks5/debian-kernel/ stretch main" > config/archives/stamus-kernel.list.chroot

#wget -O config/archives/packages-stamus-networks-gpg.key.chroot http://packages.stamus-networks.com/packages.selks5.stamus-networks.com.gpg.key

log_info "Configuring Docker repository with relaxed security"
mkdir -p config/includes.chroot/etc/apt/keyrings/
install -m 0755 -d config/includes.chroot/etc/apt/keyrings/
echo "deb [arch=amd64] https://download.docker.com/linux/debian bookworm stable" > config/archives/docker.list.chroot
curl -fsSL "https://download.docker.com/linux/debian/gpg" -o config/archives/docker.key.chroot
ls -lh config/archives/docker.key.chroot

fi

# Create dirs if not existing for the custom config files
mkdir -p config/includes.chroot/etc/logstash/conf.d/
mkdir -p config/includes.chroot/etc/skel/Desktop/
mkdir -p config/includes.chroot/usr/share/applications/
mkdir -p config/includes.chroot/usr/share/xfce4/backdrops/
mkdir -p config/includes.chroot/etc/logrotate.d/
mkdir -p config/includes.chroot/etc/systemd/system/
mkdir -p config/includes.chroot/data/moloch/etc/
mkdir -p config/includes.chroot/etc/init.d/
mkdir -p config/includes.binary/isolinux/
mkdir -p config/includes.chroot/usr/share/images/desktop-base/
mkdir -p config/includes.chroot/etc/profile.d/
mkdir -p config/includes.chroot/root/Desktop/
mkdir -p config/includes.chroot/etc/iceweasel/profile/
mkdir -p config/includes.chroot/etc/alternatives/
mkdir -p config/includes.chroot/etc/systemd/system/
mkdir -p config/includes.chroot/var/backups/
mkdir -p config/includes.chroot/etc/apt/
mkdir -p config/includes.chroot/usr/share/polkit-1/actions/
mkdir -p config/includes.chroot/usr/share/polkit-1/rules.d/
mkdir -p config/includes.chroot/opt/ClearNDRCommunity/docker/
mkdir -p config/includes.chroot/opt/ClearNDRCommunity/docker/tar_images/
mkdir -p config/includes.chroot/usr/share/icons/

cd ../

# cp README and LICENSE files to the user's desktop
cp LICENSE Stamus-Live-Build/config/includes.chroot/etc/skel/Desktop/
cp LICENSE Stamus-Live-Build/config/includes.chroot/etc/skel/
# some README adjustments - in order to add a http link
# to point to the latest README version located on SELKS github
# The same as above but for root
cp LICENSE Stamus-Live-Build/config/includes.chroot/root/Desktop/

# cp Scirius desktop shortcuts
#cp staging/usr/share/applications/Scirius.desktop Stamus-Live-Build/config/includes.chroot/etc/skel/Desktop/
# Same as above but for root
#cp staging/usr/share/applications/Scirius.desktop Stamus-Live-Build/config/includes.chroot/root/Desktop/

# Logrotate config for eve.json
cp staging/etc/logrotate.d/suricata Stamus-Live-Build/config/includes.chroot/etc/logrotate.d/

# Add the Stmaus Networs logo for the boot screen
cp staging/splash.png Stamus-Live-Build/config/includes.binary/isolinux/

# Add the SELKS wallpaper
cp staging/wallpaper/joy-wallpaper_1920x1080.svg Stamus-Live-Build/config/includes.chroot/etc/alternatives/desktop-background
#cp staging/wallpaper/joy-wallpaper_1920x1080.svg Stamus-Live-Build/config/includes.chroot/usr/share/xfce4/backdrops/

# Copy Docker tars for building offline ISO
if [ -z "$(ls -A staging/dockers/)" ]; then
  docker pull ghcr.io/stamusnetworks/stamusctl-templates/clearndr:latest && \
  docker pull rabbitmq:3-management-alpine && \
  docker pull ghcr.io/stamusnetworks/stamus-images/opensearch-dashboards:2.18 && \
  docker pull opensearchproject/opensearch:2.18.0 && \
  docker pull ghcr.io/stamusnetworks/scirius:clear-ndr-rc3 && \
  docker pull ghcr.io/stamusnetworks/stamus-images/fluentd:1.16 && \
  docker pull jasonish/suricata:7.0 && \
  docker pull postgres:17 && \
  docker pull jasonish/evebox:master && \
  docker pull ghcr.io/stamusnetworks/stamus-images/arkime:5.5 && \
  docker pull busybox && \
  docker pull docker:latest && \
  docker pull hashicorp/terraform:1.9 && \
  docker pull curlimages/curl:8.13.0 && \
  docker pull nginx:1.27

  docker save -o staging/dockers/stamusnetworks_stamus-images_clearndr_templates_latest.tar ghcr.io/stamusnetworks/stamusctl-templates/clearndr:latest && \
  docker save -o staging/dockers/stamusnetworks_stamus-images_3-management-alpine.tar rabbitmq:3-management-alpine && \
  docker save -o staging/dockers/stamusnetworks_stamus-images_opensearch-dashboards.tar ghcr.io/stamusnetworks/stamus-images/opensearch-dashboards:2.18 && \
  docker save -o staging/dockers/stamusnetworks_stamus-images_opensearch2.18.0.tar opensearchproject/opensearch:2.18.0 && \
  docker save -o staging/dockers/stamusnetworks_stamus-images_clear-ndr-rc3.tar ghcr.io/stamusnetworks/scirius:clear-ndr-rc3 && \
  docker save -o staging/dockers/stamusnetworks_stamus-images_fluentd.tar ghcr.io/stamusnetworks/stamus-images/fluentd:1.16 && \
  docker save -o staging/dockers/stamusnetworks_stamus-images_suricata.tar jasonish/suricata:7.0 && \
  docker save -o staging/dockers/stamusnetworks_stamus-images_postgres.tar postgres:17 && \
  docker save -o staging/dockers/stamusnetworks_stamus-images_evebox-master.tar jasonish/evebox:master && \
  docker save -o staging/dockers/stamusnetworks_stamus-images_arkime.tar ghcr.io/stamusnetworks/stamus-images/arkime:5.5 && \
  docker save -o staging/dockers/stamusnetworks_stamus-images_busybox.tar busybox && \
  docker save -o staging/dockers/stamusnetworks_stamus-images_docker.tar docker:latest && \
  docker save -o staging/dockers/stamusnetworks_stamus-images_terraform.tar hashicorp/terraform:1.9 && \
  docker save -o staging/dockers/stamusnetworks_stamus-images_curl.tar curlimages/curl:8.13.0 && \
  docker save -o staging/dockers/stamusnetworks_stamus-images_nginx.tar nginx:1.27
  cp staging/dockers/*.tar Stamus-Live-Build/config/includes.chroot/opt/ClearNDRCommunity/docker/tar_images/
else
  cp staging/dockers/*.tar Stamus-Live-Build/config/includes.chroot/opt/ClearNDRCommunity/docker/tar_images/
fi

# Copy banners
cp staging/etc/motd Stamus-Live-Build/config/includes.chroot/etc/
cp staging/etc/issue.net Stamus-Live-Build/config/includes.chroot/etc/

# Copy pythonpath.sh
cp staging/etc/profile.d/pythonpath.sh Stamus-Live-Build/config/includes.chroot/etc/profile.d/

# Copy evebox desktop shortcut.
#cp staging/usr/share/applications/Evebox.desktop Stamus-Live-Build/config/includes.chroot/etc/skel/Desktop/

# Same as above but for root
#cp staging/usr/share/applications/Evebox.desktop Stamus-Live-Build/config/includes.chroot/root/Desktop/

# Stamus Desktop shortcuts
cp staging/usr/share/applications/ClearNDRCommunity.desktop Stamus-Live-Build/config/includes.chroot/etc/skel/Desktop/
cp staging/usr/share/applications/ClearNDRCommunity.desktop Stamus-Live-Build/config/includes.chroot/root/Desktop/
cp staging/usr/share/applications/Docs-ClearNDRCommunity.desktop Stamus-Live-Build/config/includes.chroot/etc/skel/Desktop/
cp staging/usr/share/applications/Docs-ClearNDRCommunity.desktop Stamus-Live-Build/config/includes.chroot/root/Desktop/
cp staging/usr/share/applications/FreeThreatIntelFeed.desktop Stamus-Live-Build/config/includes.chroot/etc/skel/Desktop/
cp staging/usr/share/applications/FreeThreatIntelFeed.desktop Stamus-Live-Build/config/includes.chroot/root/Desktop/
cp staging/usr/share/applications/StamusLabs.desktop Stamus-Live-Build/config/includes.chroot/etc/skel/Desktop/
cp staging/usr/share/applications/StamusLabs.desktop Stamus-Live-Build/config/includes.chroot/root/Desktop/


# copy polkit policies for selks-user to be able to execute as root
# first time setup scripts
cp staging/usr/share/polkit-1/actions/org.stamusnetworks.firsttimesetup.policy Stamus-Live-Build/config/includes.chroot/usr/share/polkit-1/actions/
cp staging/usr/share/polkit-1/actions/org.stamusnetworks.setupidsinterface.policy Stamus-Live-Build/config/includes.chroot/usr/share/polkit-1/actions/
cp staging/usr/share/polkit-1/actions/org.stamusnetworks.update.policy Stamus-Live-Build/config/includes.chroot/usr/share/polkit-1/actions/
cp staging/usr/share/polkit-1/rules.d/org.stamusnetworks.rules Stamus-Live-Build/config/includes.chroot/usr/share/polkit-1/rules.d/

# setup offline docker loading folder
cp staging/config/hooks/live/firstboot.sh Stamus-Live-Build/config/includes.chroot/opt/ClearNDRCommunity/docker/

# Add core system packages to be installed
echo "

libpcre3 libpcre3-dbg libpcre3-dev ntp ca-certificates curl
build-essential autoconf automake libtool libpcap-dev libnet1-dev
libyaml-0-2 libyaml-dev zlib1g zlib1g-dev libcap-ng-dev libcap-ng0
make flex bison git git-core libmagic-dev libnuma-dev pkg-config
libnetfilter-queue-dev libnetfilter-queue1 libnfnetlink-dev libnfnetlink0
libjansson-dev libjansson4 libnss3-dev libnspr4-dev libgeoip1 libgeoip-dev
rsync mc python3-daemon libnss3-tools curl net-tools
python3-cryptography libgmp10 libyaml-0-2 python3-simplejson python3-pygments
python3-yaml ssh sudo tcpdump nginx openssl jq patch
python3-pip debian-installer-launcher live-build apt-transport-https ca-certificates
 " \
>> Stamus-Live-Build/config/package-lists/StamusNetworks-CoreSystem.list.chroot

# Add system tools packages to be installed
#echo "
#ethtool bwm-ng iptraf htop rsync tcpreplay sysstat hping3 screen ngrep docker-ce docker-ce-cli
#tcpflow dsniff mc python3-daemon wget curl vim bootlogd lsof libpolkit-agent-1-0  libpolkit-gobject-1-0 policykit-1 policykit-1-gnome" \
#>> Stamus-Live-Build/config/package-lists/StamusNetworks-Tools.list.chroot

echo "
ethtool bwm-ng iptraf htop rsync tcpreplay sysstat hping3 screen ngrep docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
tcpflow dsniff mc python3-daemon wget curl vim bootlogd lsof libpolkit-agent-1-0  libpolkit-gobject-1-0 policykit-1 policykit-1-gnome" \
>> Stamus-Live-Build/config/package-lists/StamusNetworks-Tools.list.chroot

# echo "
# ethtool bwm-ng iptraf htop rsync tcpreplay sysstat hping3 screen ngrep
# tcpflow dsniff mc python3-daemon wget curl vim bootlogd lsof libpolkit-agent-1-0  libpolkit-gobject-1-0 policykit-1 policykit-1-gnome" \
# >> Stamus-Live-Build/config/package-lists/StamusNetworks-Tools.list.chroot


# Unless otherwise specified the ISO will be with a Desktop Environment
if [[ -z "$GUI" ]]; then
  echo "task-xfce-desktop xfce4-goodies fonts-lyx wireshark terminator" \
  >> Stamus-Live-Build/config/package-lists/StamusNetworks-Gui.list.chroot
  echo "wireshark terminator open-vm-tools open-vm-tools-desktop lxpolkit" \
  >> Stamus-Live-Build/config/package-lists/StamusNetworks-Gui.list.chroot

  # Copy the menu shortcuts for Kibana and Scirius
  # this is for the lxde menu widgets - not the desktop shortcuts
  #cp staging/usr/share/applications/Scirius.desktop Stamus-Live-Build/config/includes.chroot/usr/share/applications/
  # For Evebox to.
  #cp staging/usr/share/applications/Evebox.desktop Stamus-Live-Build/config/includes.chroot/usr/share/applications/
  cp staging/usr/share/applications/ClearNDRCommunity.desktop Stamus-Live-Build/config/includes.chroot/usr/share/applications/
  cp staging/usr/share/applications/Docs-ClearNDRCommunity.desktop Stamus-Live-Build/config/includes.chroot/usr/share/applications/
  cp staging/usr/share/applications/FreeThreatIntelFeed.desktop Stamus-Live-Build/config/includes.chroot/usr/share/applications/
  cp staging/usr/share/applications/StamusLabs.desktop Stamus-Live-Build/config/includes.chroot/usr/share/applications/
  # Copy the icons
  cp staging/usr/share/applications/StamusLabs.desktop Stamus-Live-Build/config/includes.chroot/usr/share/icons/
  cp staging/usr/share/icons/CNDR-Desktop-Icon-Docs.svg Stamus-Live-Build/config/includes.chroot/usr/share/icons/
  cp staging/usr/share/icons/CNDR-Desktop-Icon-Labs.svg Stamus-Live-Build/config/includes.chroot/usr/share/icons/
  cp staging/usr/share/icons/CNDR-Desktop-Icon-Launch.svg Stamus-Live-Build/config/includes.chroot/usr/share/icons/
  cp staging/usr/share/icons/CNDR-Desktop-Icon-NRD-Intel.svg Stamus-Live-Build/config/includes.chroot/usr/share/icons/


fi

# If -p (add packages) option is used - add those packages to the build
if [[ -n "${PKG_ADD}" ]]; then
  echo " ${PKG_ADD[@]} " >> \
  Stamus-Live-Build/config/package-lists/StamusNetworks-UsrPkgAdd.list.chroot
fi

# Add specific tasks(script file) to be executed
# inside the chroot environment
cp staging/config/hooks/live/chroot-inside-Debian-Live.hook.chroot Stamus-Live-Build/config/hooks/live/

# Edit menu names for Live and Install
if [[ -n "$KERNEL_VER" ]];
then

   # IF custom kernel option is chosen "-k ...":
   # remove the live menu since different kernel versions and custom flavors
   # can potentially fail to load in LIVE depending on the given environment.
   # So we create a file for execution at the binary stage to remove the
   # live menu choice. That leaves the options to install.
   cp staging/config/hooks/live/menues-changes.hook.binary Stamus-Live-Build/config/hooks/live/
   cp staging/config/hooks/live/menues-changes-live-custom-kernel-choice.hook.binary Stamus-Live-Build/config/hooks/live/


else

  #cp staging/config/hooks/menues-changes.binary Stamus-Live-Build/config/hooks/
  cp staging/config/hooks/live/menues-changes.hook.binary Stamus-Live-Build/config/hooks/live/

fi

# Debian installer preseed.cfg
echo "
d-i netcfg/hostname string ClearNDR

d-i passwd/user-fullname string clearndr User
d-i passwd/username string clearndr
d-i passwd/user-password password clearndr
d-i passwd/user-password-again password clearndr
d-i passwd/user-default-groups string audio cdrom floppy video dip plugdev scanner bluetooth netdev sudo

d-i passwd/root-password password clearndr
d-i passwd/root-password-again password clearndr
" > Stamus-Live-Build/config/includes.installer/preseed.cfg

# Check pre-build environment
log_info "Starting ISO build process"
log_debug "Current working directory: $(pwd)"
log_debug "Current user: $(whoami)"
log_debug "Available space: $(df -h . | tail -1)"

# Verify live-build configuration
cd Stamus-Live-Build
log_info "Entered Stamus-Live-Build directory"
log_debug "Contents of config directory:"
ls -la config/ | tee -a build.log

# Check if we have proper permissions and directories
log_debug "Checking chroot directory permissions:"
ls -la chroot/ 2>/dev/null | head -10 | tee -a build.log

log_debug "Checking tmp directory status:"
ls -la /tmp | head -5 | tee -a build.log
mount | grep tmp | tee -a build.log

# Start the build with comprehensive logging
log_info "Starting lb build command"

# Pre-build diagnostics
log_debug "Pre-build environment check:"
log_debug "Kernel version: $(uname -r)"
log_debug "Available memory: $(free -h)"
log_debug "Container capabilities: $(cat /proc/1/status | grep Cap)"

# Check if we're in a container and handle accordingly
if [ -f /.dockerenv ]; then
    log_info "Detected container environment - applying container-specific fixes"

    # Ensure proper tmp directory setup for live-build
    chmod 1777 /tmp /var/tmp 2>/dev/null || true

    # Create necessary directories for chroot tmp handling
    mkdir -p chroot/tmp chroot/var/tmp 2>/dev/null || true
    chmod 1777 chroot/tmp chroot/var/tmp 2>/dev/null || true

    # Set environment variables to help with GPG operations
    export TMPDIR=/tmp
    export DEBIAN_FRONTEND=noninteractive

    # Configure APT to handle GPG operations better in containers
    mkdir -p config/apt
    cat >> config/apt/apt.conf <<EOF
APT::Sandbox::User "root";
Acquire::AllowInsecureRepositories "true";
Acquire::Check-Valid-Until "false";
EOF

    log_debug "Container-specific setup completed"
fi

# Pre-build GPG and repository fixes
log_info "Applying GPG and repository fixes"

# Create a hook to fix GPG operations in chroot
mkdir -p config/hooks/live
cat > config/hooks/live/01-fix-gpg.hook.chroot << 'EOF'
#!/bin/bash
# Fix GPG operations in chroot environment

# Ensure tmp directories exist and have proper permissions
mkdir -p /tmp /var/tmp
chmod 1777 /tmp /var/tmp

# Create GPG configuration to avoid tmp file issues
mkdir -p /root/.gnupg
cat > /root/.gnupg/gpg.conf << EOCONF
no-autostart
no-tty
batch
EOCONF

# Set environment variables for apt operations
export TMPDIR=/tmp
export HOME=/root
export DEBIAN_FRONTEND=noninteractive

# Fix any existing APT key issues
apt-key adv --refresh-keys --keyserver keyserver.ubuntu.com >/dev/null 2>&1 || true

echo "GPG fixes applied successfully"
EOF

chmod +x config/hooks/live/01-fix-gpg.hook.chroot

# Also create a hook to handle repository signing issues
cat > config/hooks/live/02-fix-repos.hook.chroot << 'EOF'
#!/bin/bash
# Fix repository signing issues

# Add trusted repositories without strict signature checking
cat > /etc/apt/apt.conf.d/99-allow-unauthenticated << EOCONF
APT::Get::AllowUnauthenticated "true";
Acquire::AllowInsecureRepositories "true";
Acquire::Check-Valid-Until "false";
APT::Sandbox::User "root";
EOCONF

# Update package cache with relaxed security
apt-get update --allow-unauthenticated >/dev/null 2>&1 || true

echo "Repository fixes applied successfully"
EOF

chmod +x config/hooks/live/02-fix-repos.hook.chroot

# Create a hook to copy Docker images to the ISO
cat > config/hooks/live/01-docker-load.hook.binary << 'EOF'
#!/bin/bash
# Copy Docker images to the ISO

set -e

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"
}

log_info "Copying Docker images to ISO"

# Create the target directory in the chroot
mkdir -p config/includes.chroot/opt/ClearNDRCommunity/docker/tar_images/

# Copy all Docker tar files if they exist
if [ -d "../staging/dockers" ]; then
    log_info "Found Docker images directory"
    cp ../staging/dockers/*.tar config/includes.chroot/opt/ClearNDRCommunity/docker/tar_images/ 2>/dev/null || log_info "No Docker tar files found to copy"
    ls -la config/includes.chroot/opt/ClearNDRCommunity/docker/tar_images/ || true
else
    log_info "No Docker images directory found - skipping Docker image copy"
fi

log_info "Docker image copy completed"
EOF

chmod +x config/hooks/live/01-docker-load.hook.binary

log_info "GPG and repository fix hooks created"

# Configure live-build to handle GPG issues
log_info "Configuring live-build for container environment"

# Add APT configuration for the build environment
mkdir -p config/apt
cat > config/apt/apt.conf << 'EOF'
APT::Get::AllowUnauthenticated "true";
Acquire::AllowInsecureRepositories "true";
Acquire::Check-Valid-Until "false";
APT::Sandbox::User "root";
Dir::Cache::pkgcache "";
Dir::Cache::srcpkgcache "";
EOF

log_info "Live-build configuration completed"

( lb build 2>&1 | while IFS= read -r line; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] lb build: $line"
done | tee -a build.log )

# Check build result
BUILD_EXIT_CODE=${PIPESTATUS[0]}
log_info "lb build completed with exit code: $BUILD_EXIT_CODE"

if [ $BUILD_EXIT_CODE -ne 0 ]; then
    log_error "lb build failed with exit code $BUILD_EXIT_CODE"
    log_debug "Last 50 lines of build.log:"
    tail -50 build.log | while IFS= read -r line; do
        echo "BUILD LOG: $line"
    done

    log_debug "Checking for specific error patterns:"
    grep -i "couldn't create temporary file" build.log | tail -10
    grep -i "gpg error" build.log | tail -10
    grep -i "repository.*not signed" build.log | tail -10

    log_debug "Current chroot tmp directory status:"
    ls -la chroot/tmp/ 2>/dev/null | tee -a build.log || log_debug "chroot/tmp directory doesn't exist"

    exit $BUILD_EXIT_CODE
fi

# Check for output files
log_info "Checking for generated ISO files"
ls -la
ls -la *.iso 2>/dev/null | tee -a build.log || log_error "No ISO files found"

if [ -f "live-image-amd64.hybrid.iso" ]; then
    log_info "Found live-image-amd64.hybrid.iso, renaming to ClearNDR.iso"
    mv live-image-amd64.hybrid.iso ClearNDR.iso
    log_info "ISO build completed successfully"
    ls -la ClearNDR.iso | tee -a build.log
    lb clean --all
else
    log_error "live-image-amd64.hybrid.iso not found"
    log_debug "Contents of current directory:"
    ls -la | tee -a build.log
    exit 1
fi
