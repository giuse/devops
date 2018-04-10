




# WORK IN PROGRESS
# Currently not working
exit 1








# #!/bin/bash

# # Back up your home (minus exclusions) to a crypted remote partition

# # args check
# # if [ "$#" != 2 ]; then
# #   echo -e "\nUSAGE: $(basename "$0") <partition> <key_file_path>"
# #   echo -e "\nwhere:"
# #   echo -e "\t<partition>:      pre-partitioned space to use for encryption (e.g. '/dev/sda2')"
# #   echo -e "\t<key_file_path>:  where to store the generated key-file that unlocks the partition"
# #   echo -e "\n IMPORTANT: make first the partition you want to crypt (e.g. with `gparted`; will be re-formatted)"
# #   exit 1
# # fi

# origin=/home/giuse/testbackup/
# destination=/media/giuse/backup/
# exclusions=/home/giuse/.backup_exclude

# # open the crypted partition on the server
# # rsync in it
# # rsync -ahzP --exclude-from ${exclusions} ${origin} ${destination}
# # close the remote partition


# # user check
# if [ "$EUID" != 0 ]; then
#    echo "This script must be run as root."
#    exit 1
# fi

# partition=/dev/sdb1
# mountpoint=/media/giuse/backup
# keyfile=/home/giuse/.keyfile_free_backup_on_flexo.key

# # open the crypto device
# cryptsetup open --type luks --key-file ${keyfile} ${partition} backup
# # mount the partition
# mount /dev/mapper/backup ${mountpoint}

server=flexo
origin=/home/giuse/testbackup/
destination=/media/giuse/backup/testbackup/
# exclusions=/home/giuse/backup_exclude

if [ -z "${exclusions}" ]; then
  echo "  WARNING: exclusions file not provided!"
else
  if [ ! -f "${exclusions}" ]; then
    echo "  ABORT: exclusions file not found: '${exclusions}'"
    exit 1
  fi
  exclusions="--exclude-from ${exclusions}"
fi

# # wait for backup...
echo "Backing up '${origin}' into '${destination}' on server '${server}'"
rsync -ahzP ${exclusions} ${origin} ${server}:${destination}

# # unmount the partition
# umount ${mountpoint}
# # close the crypto device
# cryptsetup close backup
