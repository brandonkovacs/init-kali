#!/bin/bash

# Only run as root
if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

# Home folders to create and symlink within shared vmware folder
HOME_FOLDERS=("bin" "src" "vpn" "workspace")

# Directory to install git repos (Customize as needed)
export REPO_DIR="/opt"

# Get Kali user and Kali Vmware Shared Directory
KALI_USER=$(ls /home/ | head -n1)
KALI_USER_HOME="/home/$KALI_USER"
KALI_SHARE=$(vmware-hgfsclient | head -n1)
KALI_SHARE_MNT="/mnt/hgfs/$KALI_SHARE"
INIT_KALI_DIR=$(dirname $(readlink -f $0))

# Copy bash profile and tmux preferences
cat "$INIT_KALI_DIR/profiles/bash_profile.txt" > "/home/$KALI_USER/.bash_profile"
cat "$INIT_KALI_DIR/profiles/bash_aliases.txt" > "/home/$KALI_USER/.bash_aliases"
cat "$INIT_KALI_DIR/profiles/tmux.conf.txt" > "/home/$KALI_USER/.tmux.conf"

# Mount Kali Shared Directory
if [ ! -d "$KALI_SHARE_MNT" ]; then
  /usr/bin/vmhgfs-fuse .host: /mnt -o allow_other
fi

# Regenerate SSH Keys
rm -rf /etc/ssh/ssh_host_*
dpkg-reconfigure openssh-server

# Symlink home folders to shared folders
for folder in "${HOME_FOLDERS[@]}"; do
  if [ ! -d "$KALI_USER_HOME/$folder" ]; then

    # Ensure shared subfolder exists, create otherwise
    if [ ! -d "$KALI_SHARE_MNT/$folder" ]; then
      mkdir -p "$KALI_SHARE_MNT/$folder"
    fi

    # Map a symlink from home subfolder to shared folder
    ln -s "$KALI_SHARE_MNT/$folder" "$KALI_USER_HOME/$folder"

  fi
done

# Update system
echo "Updating system..."
apt -y clean all && apt -y update && apt -y upgrade && apt -y autoremove

# Install apt packages
echo "Installing apt packages..."
  for a in $(cat "$INIT_KALI_DIR/apt-packages.txt" | sort -u); do apt -y install "$a"; done

# Iterate through list of git repos and clone or pull any updates
echo "Installing git repos..."
for r in $(cat "$INIT_KALI_DIR/github-repos.txt" | grep github | sort -u); do

  # Cut git repo folder name from .git repo url
  folder=$(echo "$r" | cut -d '/' -f5 | sort -u | grep git | cut -d '.' -f1)

  echo "Processing repo: $folder"

  # check if repo exists or not
  if [ ! -d "$REPO_DIR/$folder" ]; then
    cd "$REPO_DIR" && git clone "$r"
  else
    cd "$REPO_DIR/$folder" && git pull
  fi
done

# Assign ownership of repo dir to kali user
chown -R "$KALI_USER:$KALI_USER" "$REPO_DIR"

# Install any custom tools
for i in $(ls "$INIT_KALI_DIR/tools.d"); do
  bash "$INIT_KALI_DIR/tools.d/$i"
done

# Fix ownership of bash profile, etc for KALI_USER
chown -R "$KALI_USER:$KALI_USER" "$KALI_USER_HOME"
