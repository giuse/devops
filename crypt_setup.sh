#!/bin/bash

# Prepare a key-accessed encrypted partition on your system.
# This is how I prepare a partition to unlock and mount by hand, typically to store my backups.

# Keep the key file in a SAFE location, possibly off the computer, or at least itself in an encrypted partition! And back it up!
# For simplicity, make first the partition you want to crypt (will be re-formatted), e.g. with `gparted`

# Need to run as root
if [[ "$EUID" != 0 || "$SUDO_USER" == "" ]]; then
  notroot=1
  echo -e "\n\t[[ This script must be run with 'sudo'. ]]\n"
fi

# args check / usage
if [[ "$#" != 3 || $notroot ]]; then
  echo -e "\nUSAGE: $(basename "$0") <partition> <conf_path> <mount_point>"
  echo -e "\nwhere:"
  echo -e "\t<partition>:\t pre-partitioned space to use for encryption\n\t\t\t (e.g. '/dev/sda2')"
  echo -e "\t<conf_path>:\t where to store the generated key-file that unlocks\n\t\t\t the partition, the configuration file, and the\n\t\t\t scripts to mount/umount the partition"
  echo -e "\t<mount_point>:\t where to mount the transparent decryption device"
  echo -e "\n  IMPORTANT: create the partition you want to crypt (e.g. with 'gparted';\n  it will be re-formatted) BEFORE using this script!"
  exit 1
fi

# configuration
partition="$1"   # e.g. /dev/sdb1
conf_dir="$2"    # e.g. ${HOME}/crypt_setup
mount_point="$3" # e.g. "/media/${SUDO_USER}/backup"

keyfile_name="keyfile.key"
keyfile="${conf_dir}/${keyfile_name}"
conf_file="${conf_dir}/conf.dat"
device="crypt"
fstype="ext4"


# create the keyfile (random), read-only
mkdir -p "${conf_dir}"
dd if=/dev/urandom of="${keyfile}" bs=1024 count=4 2>/dev/null
chmod 0400 "${keyfile}"

# # format the partition with a crypted filesystem - will ask for a passphrase
# cryptsetup --batch-mode luksFormat "${partition}" "${keyfile}"
# # mount the partition - will create device for transparent access
# cryptsetup open --type luks --key-file "${keyfile}" "${partition}" "${device}"
# # format the partition
# mkfs.${fstype} "/dev/mapper/${device}"
# create the mount-point and test-mount the partition
mkdir -p "${mount_point}"
# # mount "/dev/mapper/${device}" "${mount_point}"
# take possession
chown -R ${SUDO_USER}:${SUDO_USER} "${mount_point}"
# access tests
testfile="${mount_point}/__DELETEME__test_file__"
touch "${testfile}"
echo "test" > "${testfile}"
rm -f "${testfile}"
# finally: unmount the partition, close access, delete the temporary mount_point
# # umount "${mount_point}"
# # cryptsetup close "${device}"


# Write the configuration file
cat > "${conf_file}" <<EOF
# Feel free to edit this configuration if e.g. you move the keyfile
partition="${partition}"
keyfile="${keyfile_name}"
mount_point="${mount_point}"
device="${device}"
EOF

# Write the "mount.sh" script
cat > "${conf_dir}/mount.sh" <<EOF
#!/bin/bash
# Mount crypted partition

if [ "\$EUID" != 0 ]; then
   echo "This script must be run as root."
   exit 1
fi

# load configuration
source "${conf_file}"
# open the crypto device
cryptsetup open --type luks --key-file "\${keyfile}" "\${partition}" "\${device}"
# mount the partition
mount "/dev/mapper/\${device}" "\${mount_point}"

echo "Crypted partition mounted on '\${mount_point}'"
EOF

# Write the "umount.sh" script
cat > "${conf_dir}/umount.sh" <<EOF
#!/bin/bash
# Umount crypted partition

if [ "\$EUID" != 0 ]; then
   echo "This script must be run as root."
   exit 1
fi

# load configuration
source "\${conf_file}"
# unmount the partition
umount "\${mount_point}"
# close the crypto device
cryptsetup close "\${device}"

echo "Crypted partition umounted"
EOF

# make conf directory content access user-read only
chmod -R 0400 "${conf_dir}"
chmod u+x "${conf_dir}"
# make mount scripts executable by owner
chmod u+x "${conf_dir}/mount.sh" "${conf_dir}/umount.sh"
# take possession
chown -R ${SUDO_USER}:${SUDO_USER} "${conf_dir}"

echo "Done! Configuration and scripts are in '${conf_dir}'"
echo "Mount crypted partition with \`${conf_dir}\mount.sh\` and umount with \`${conf_dir}\umount.sh\`"
echo -e "\nREMEMBER to back up the keyfile!!\n\t ${keyfile}\n"
