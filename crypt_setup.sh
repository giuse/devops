#!/bin/bash

# Prepare a key-accessed encrypted partition on your system.
# This is how I prepare a partition to unlock and mount by hand, where I store my backups.

# IMPORTANT: keep the key file in a SAFE location, possibly off the computer, or at least itself encrypted! And back it up!
# IMPORTANT: for simplicity, make first the partition you want to crypt (will be re-formatted), e.g. with `gparted`
# This script must be run as root.

# user check
if [ "$EUID" != 0 ]; then
   echo "This script must be run as root." 
   exit 1
fi

# args check
if [ "$#" != 2 ]; then
  echo -e "\nUSAGE: $(basename "$0") <partition> <key_file_path>"
  echo -e "\nwhere:"
  echo -e "\t<partition>:      pre-partitioned space to use for encryption (e.g. '/dev/sda2')"
  echo -e "\t<key_file_path>:  where to store the generated key-file that unlocks the partition"
  echo -e "\n IMPORTANT: make first the partition you want to crypt (e.g. with `gparted`; will be re-formatted)"
  exit 1
fi

# configuration (no need for `shift`)
partition="$1"   # /dev/sdb1
keyfile="$2"     # ${HOME}/backup_keyfile.key

# create the keyfile (random) and change permissions to root-only
dd if=/dev/urandom of=${keyfile} bs=1024 count=4
chmod 0400 ${keyfile}
# format the partition with a crypted filesystem - will ask passphrase
cryptsetup --batch-mode luksFormat ${partition} ${keyfile}
# mount the partition - will create `/dev/mapper/crypt_test` for transparent access
cryptsetup open --type luks --key-file ${keyfile} ${partition} crypt_test
# format the partition (ext4 here)
mkfs.ext4 /dev/mapper/crypt_test 
# create a test mountpoint and test-mount the partition
mountpoint=$(mktemp -d)
mount /dev/mapper/crypt_test ${mountpoint}
# take possession
chown -R ${USER}:${USER} ${mountpoint}
# finally unmount the partition, close the transparent access, and delete the temporary mountpoint
umount ${mountpoint}
cryptsetup close crypt_test

# did you remember to back up the keyfile?
echo -e "\nRemember to move or back up the keyfile:\n\t ${keyfile}\n"
