#!/bin/bash
# rbackup - remote backup utility - version 1.5 (oct11)
# Copyright 2011 Giuseppe Cuccu, all rights reserved
# This script is provided AS I USE IT and under constant updating - NO WARRANTY
#
# Keeping regular backups of your important data would be best.
# Unfortunately there is not a single, easy tool, to just launch at will,
# which safely and incrementally backs up a desired folder.
#
#                     Well, there WASn't.
#
# - ORIG is the (list of) files/folders to backup
# - REM is the host to hold the backup snapshots (leave empty for local)
# - BKPD is the name of the folder to contain all the snapshots
# - optionally, set EXCLS to the stuff you want to exclude
#
#                    AND YOU'RE GOOD TO GO
# Just launch the script every time you feel like saving a new snapshot
#

# PLEASE NOTE:
# - Your original data is SAFE, this is a read-only script
# - Your destination directory is NOT SAFE, as this will wipe it to mirror the origin
# - No old snapshot is deleted before a new one is completed and verified for consistency
#
# - Remember to setup the variables the first time you get the script
# - The first call needs to transfer all the data - this may take some time
# - Further calls will create new incremental backups while rotating the snapshots
# - Provide any argument from command line to augment the number of snapshots to maintain
# - You can access all snapshots at any time as normal files - current snapshot is linked
# - TIP: set up shared keys authentication for ssh first (see my other scripts)




##### VARIABLES TO SET

#  List of files and folders to backup
  orig="/home/giuse"
#  Remote server to hold the backups (leave empty for local machine)
  rem="giuse@bkpsrv"
#  Folder on ${rem} where the backups will be stored
  bkpd="/home/giuse/backup"
#  List of paths to exclude from backup
#  - can use regular expressions
#  - a / at the beginning means start from ${orig}
#  - a / at the end means "all directory content"
#  - example: add "/.*/" to exclude all hidden directories in ${orig}
#  Have a look at the rsync man page for complete reference
  excls="
    /exclude/
    /.dropbox-dist/
    /android/
    /.gconfd/
    /.rnd
    /.kde/
    /.local/
    /.gconf/
    /.cache/
    /.thumbnails/
    /.config/
    /.dropbox/
    /.mozilla/
    /Archive/Dropbox/.dropbox.cache/
    /.xsession*
    /.gvfs/
    /.wine/
  "

#### ANDROID BACKUP QUICK HACK!!!

if [ "$1" == "android" ]; then
  bkpd="/home/giuse/backup_android"
  orig="/media/042F-1590"
  excls=""
  shift
fi

##### DONE! YOU CAN LAUNCH THE SCRIPT NOW!





# INTERACTION TWEAK: Uncomment these for a minimum level of interaction
#
#orig=$(zenity --file-selection --multiple --title="Directory to backup" \
#       --text="Enter backup origin:" --entry-text="${orig}")
rem=$(zenity --entry --title="Backup server" \
      --text="Enter backup server:" --entry-text="${rem}")
#bkpd=$(zenity --entry --title="Backup directory" \
#       --text="Enter backup destination:" --entry-text="${bkpd}")


# Starting time in seconds
time=$( date +%s )
# Execute a command on the backup server - through ssh if remote
if [ "${rem}" ]; then rcmd="ssh ${rem}"; fi
# Make sure backup directory exists
${rcmd} mkdir -p "${bkpd}"
# Temporary backup folder on remote server
tmp="${bkpd}/backup_tmp"
# Symlink to lastest snapshot
cur="${bkpd}/current"
# Folder name for the new backup - with human-readable time information
dest="${bkpd}/$( date +%d_%b_%H:%M )" # next line is just to allow more than a backup per minute
if [ -d "${dest}" ]; then dest="${bkpd}/$( date +%d_%b_%H:%M:%S )"; fi
# File containing what will be excluded from the backup
exclf="${orig}/backup_exclusions"
# Trick to select the currently oldest backup in the folder
oldestbk="${bkpd}/$(${rcmd} ls -tr1 ${bkpd} | head -1)"
# Trick to count how many snapshots are presently maintained
nvers=$( ${rcmd} ls -1 ${bkpd} -I $(basename ${cur}) -I $(basename ${tmp}) | wc -l )
# Write down exclusions file
echo ${excls} | sed 's/ /\n/g' > ${exclf}
# Append column to rem if defined - makes it compatible with local paths
if [ "${rem}" ]; then rem="${rem}:"; fi


# RSYNC: Try to create a new backup
# rsync based - suggested flags: azhP
# a -> archive mode, z -> compress, h -> human-readable, P -> show progress
# remove z on low-end machines, remove h and P for cron usage

#echo "Starting backup..."
rsync -azhP \
  --delete --delete-excluded \
  --exclude-from=${exclf} \
  --link-dest=${cur} \
  "${orig}/"  "${rem}${tmp}"
#echo "Backup done!"


# If rsync was successful:
if [ $? -eq 0 ]
then
  # Make the temporary backup definitive and current
  ${rcmd} mv "${tmp}" "${dest}"
  ${rcmd} rm -f "${cur}"
  ${rcmd} ln -s "${dest}" "${cur}"
  # Delete oldest backup - unless args provided, or making the first snapshot
  if [ $# -lt 1  -a  ${nvers} -gt 0 ]
  then
    echo -e "\nRemoving oldest backup, please wait..."
    ${rcmd} rm -rf "${oldestbk}"
  fi
  echo -e "\n\tSUCCESS!\n"

# Show error if rsync failed!
else
  echo -e "\n\tFAIL!!\n\tRSYNC BACKUP ERROR\n"
fi

# Remove exclusions list from ${orig} (you can still find them in the backup)
rm -f ${exclf}

# Pretty print some infos
curnvers=$( ${rcmd} ls -1 ${bkpd} -I $(basename ${cur}) -I $(basename ${tmp}) | wc -l )
totsec=$[ $(date +%s) - ${time} ]
totmin=$(echo -e "scale=1;${totsec}/60.0" | bc)
tothou=$(echo -e "scale=1;${totsec}/3600.0" | bc)
echo -ne "\tTotal time: "
if [ ${totsec} -ge 3600 ]; then echo -e ${tothou} "hours"
else if [ ${totsec} -ge 60 ]; then echo -e ${totmin} "minutes"
else echo -e ${totsec} "seconds"; fi; fi;echo -e "\tBackup stored at  ${rem}${cur}"
echo -e "\tYou are currently maintaining ${curnvers} versions.\n"


# Done!



# TODO list
# Feel free to suggest more points (or participate coding) at giuse@idsia.ch
# - Save settings in hidden file, ask interactively to set them the first time, then
#   just source the file to get the variables: what, server, dest, #vers, exclusions
# - If argument provided, ask to edit the settings file
# - Check if zenity exist and switch between zenity- and terminal-based interaction
# - The window-based version could just present all settings in editable format
# - A tickbox on the window should allow the user to save the entries as defaults
# - Basic cron setup example or automatic setting


