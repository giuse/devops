#!/bin/bash
# rbackup - remote backup utility - version 2.3 - July 2013
# Copyright © 2011 2012 2013 Giuseppe Cuccu - all rights reserved
# This script is provided AS USED and under constant updating - NO WARRANTY


# Initialization and intro
intro() {
  # where to look for configuration file
  conf_file="${HOME}/.rbackup.conf"
  starting_time=$( date +%s )
  echo -e "\n\t rbackup"
  echo
}


# Check if the config file is present, create it otherwise
load_conf() {
  if [[ ! -f "${conf_file}" ]]; then
    echo "Config file ${conf_file} not found - creating"
    write_conf_file
    echo "Config file ${conf_file} created - please customize it and try again"
    exit 1
  fi
  source ${conf_file}
}


# Set destination variables: srv, srvp, path
set_dest () {

  # process array of lists of words in input
  for deststr in "${dest_lst[@]}"; do
    dest=($deststr)

    # type of dest depends on number of params: 1 -> local, 2 -> remote, 3 -> remote+port
    dest_type=${#dest[@]}
    case $dest_type in
      1 )
        unset srv;         unset srvp;         path=${dest[0]}
        echo -e "  Accessing local directory\n    Path: ${path}"
        ;;
      2 )
        srv=${dest[0]};    srvp=22;            path=${dest[1]}
        echo -e "  Accessing remote server\n    Server: ${srv} - Path: ${path}"
        ;;
      3 )
        srv=${dest[0]};    srvp=${dest[1]};    path=${dest[2]}
        echo -e "  Accessing remote server\n    Server: ${srv} - Port: ${srvp} - Path: ${path}"
        ;;
      * )
        echo "  ERROR! One of the destinations has a wrong number of arguments! Check config file!"
        echo ${dest[@]}
        exit 1
        ;;
    esac

    if accessible ; then  # if the current configuration is accessible for backup
      echo "      OK!"
      local dest_found=0       # accessible destination found
      break               # exit the loop
    else
      echo "      FAIL"
    fi
  done
  echo
  # unless found accessible destination, give error and exit
  if [[ -z ${dest_found} ]]; then
    echo "ERROR! None of the destinations provided was accessible!"
    exit 1
  fi
}


# Verify if current location is accessible
accessible() {
  case $dest_type in
    1 ) # local
      [[ -d $path ]]
      ;;
    2|3 ) # remote
      nc -zw 10 $srv $srvp 2> /dev/null && ssh $srv -p $srvp test -d $path
      ;;
    * ) # error
      echo "ERROR! unrecognized type!"
      exit 1
      ;;
  esac
}


# Set system variables based on configuration
pre_call() {
  # rcmd will send the commands to the remote server, if present
  if [[ $dest_type -eq 2 || $dest_type -eq 3 ]]; then
    rcmd="ssh -p ${srvp} ${srv}";  else  unset rcmd;  fi

  tmp="${path}/partial"                              # Temporary backup folder on destination
  cur="${path}/current"                              # Symlink to current (latest) snapshot
  while ! ${rcmd} [[ -d "${cur}" ]]; do force_create_cur; done   # Enforce the use of --link-dest feature
  dest="${path}/$( date +%y%m%d__%a_%d_%b__%H:%M )"  # Time-based named backup destination directory
  if ${rcmd} [[ -d "${dest}" ]]; then dest+="$( date +:%S )"; fi # Add seconds if multiple backups per minute
}


# Forces creation of link to current backup if not present
force_create_cur() {
  newest="${path}/$( ${rcmd} ls -t1 -I ${cur} -I ${tmp} ${path} | head -1 )"
  echo -e "  BEWARE! Link to latest backup not found\n    -> cannot continue\n  Most recent backup:\n    ${newest}\n  Required link name:\n    ${cur}\n  Link name:\n    ${cur}"
  read -p "  Do you wish me to create it for you? [y/n]: " -n 1 -r
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    echo -e "\n\n  Creating link to latest backup...\n"
    ${rcmd} ln -s "${newest}" "${cur}"
  else
    echo -e "\n\nERROR: Link to latest backup not found."
    exit 1
  fi
}


# rsync main call:
# backup main folder, propagate deletions, use exclusion list
rsync_main() {
  rsync_origin="${origin}/"
  rsync_dest="${tmp}"
  rsync_current="--link-dest=${cur}"
  rsync_deletion="--delete --delete-excluded"
  rsync_exclusion=$(  # add from exclusions
    for excl in ${exclusions}; do
      echo -n " --exclude $excl"; done)
  rsync_exclusion+=$( # add from up-only folders
    for up in "${up_only[@]}"; do
      echo -n " --exclude /${up%% *}/"; done ) # first element
  echo -e "  Main backup:\n    ${rsync_origin}"
  rsync_call
  echo
}


# rsync up-only calls:
# upload from up_only list, don't propagate deletions, ignore exclusion list
rsync_uponly() {
  unset rsync_current
  unset rsync_deletion
  unset rsync_exclusion
  for up in "${up_only[@]}"; do
    rsync_origin="${origin}/${up%% *}/" # first element
    rsync_dest="${path}/${up##* }"      # last element
    if [[ -d "${rsync_origin}" ]]; then
      echo -e "  Synchronizing:\n    ${rsync_origin}"
      rsync_call
      echo
    else
      echo -e "  Not found:\n    ${rsync_origin}\n -- skipping..."
      echo
    fi
  done
}


# rsync call
rsync_call(){

  # build rsync destination
  rsync_dest="${srv+${srv}:}${rsync_dest}"
  rsync_rsh="${srvp+--rsh=ssh -p ${srvp}}"

  rsync_flags='-'
  rsync_flags+='a'       #  archive mode
  rsync_flags+='z'       #  compress data
  rsync_flags+='h'       #  human readable sizes
  rsync_flags+='P'       #  show progress

  # Main call
  echo "      Launching rsync"
  # (set -x # uncomment subshell to print rsync command expansion
  rsync                 \
    ${rsync_flags}      \
    "${rsync_rsh}"      \
    ${rsync_deletion}   \
    ${rsync_exclusion}  \
    ${rsync_current}    \
    ${rsync_origin}     \
    ${rsync_dest}
  # ) # uncomment subshell to print rsync command expansion

  # If failed, show error and exit
  if [[ $? -ne 0 ]]; then
    echo "ERROR!! rsync reported an error status"
    exit 1
  fi

}


# count the number of versions currently maintained
update_nvers() { nvers=$( ${rcmd} ls -l ${path} -I ${cur} -I ${tmp} | grep ^d | wc -l ); }


# Round up after the main call
post_main() {

  ${rcmd} mv "${tmp}" "${dest}"     # Make the temporary backup definitive
  ${rcmd} rm -f "${cur}"            # Remove previous current link
  ${rcmd} ln -s "${dest}" "${cur}"  # Make the new backup current
  ${rcmd} touch "${dest}"           # Fix creation time of new backup

  # Count the number of versions
  update_nvers

  # If there are more versions than desired, delete oldest backups
  # (if they're less, this number will grow with each new backup)
  while [[ ${nvers} -gt ${desired_vers} ]]; do
    oldest="${path}/$( ${rcmd} ls -tr1 ${path} | head -1 )"
    echo -e "\n  Removing oldest backup:\n    ${oldest} \n      please wait..."
    ${rcmd} rm -rf "${oldest}"
    update_nvers
  done
}


# Calculate the total time and print some stats
print_time() {
  echo -e "\n\t SUCCESS!\n"
  tot_s=$(( $(date +%s) - ${starting_time?"ERROR!! Set starting_time at beginning of script!"} ))
  tot_m=$(echo -e "scale=1;${tot_s}/60.0"   | bc)
  tot_h=$(echo -e "scale=1;${tot_s}/3600.0" | bc)
  echo -e "  Total time:"
  if   [[ ${tot_s} -ge 3600 ]]; then echo -e "    ${tot_h} hours"
  elif [[ ${tot_s} -ge 60 ]];   then echo -e "    ${tot_m} minutes"
  else                               echo -e "    ${tot_s} seconds"
  fi
  echo -e "  Backup stored at:\n    ${srv+${srv}:}${dest}"
  echo -e "  You are currently maintaining  ${nvers}  versions.\n"
}


# Write down a default configuration file
write_conf_file() {
  local conf='#!/bin/bash\n# rsync configuration\n#\n# THIS IS JUST AN EXAMPLE -- customize this file before using it!\n# NOTE: be very careful to escaping spaces in paths!!!\n\n
# `origin` is The One, what you want to mirror in your backups\norigin="${HOME}"\n
# How much redundancy is enough? You choose how often you backup, and you choose\n# how many versions to keep.\n#
# `desired_vers` is the number of versions you wish to maintain\n# all backups older than the first `desired_vers` will be deleted!
desired_vers=5\n\n
# Sometimes you backup to an external HDD for speed. Then you just connect it to\n# a home server and leave it there. Sometimes you backup to it through the LAN,\n# sometimes from outside. You need that flexibility.\n#
# `dest_lst` is a prioritized array of where to find/add your backups\n# destinations are strings that look like this: `[server [port]] local_path`\n# Add one destination per line, the first working destination will be used
dest_lst=( "/media/giuse/backup_hd/giuse"                        # backup drive mounted locally (USB)\n           "bkpsrv.local  /backup_hd/giuse"                      # backup drive mounted to local server (LAN)\n           "mydns.dyndnsprovider.com  8080  /backup_hd/giuse" )  # backup from outside my LAN\n\n
# Having a large archive of music but wanting to carry around just few albums?\n# Or same deal with pictures, ebooks, videos, software?\n# These destinations will update any modification to files you have a copy of,\n# so you can change the tags on MP3 files locally then upload.\n# Any new file will be uploaded too, like new pictures or videos. But files not\n# found locally will not be deleted from the destination.\n# Note how these files often tend to be private on a laptop, but shared in a\n# home environment. Hence the destination often leaving the private backup folder.\n#
# `up_only` is an array of couples of paths RELATIVE to the above `origin` and destination\n# each points to an archive you want to keep updated but do not want to entirely carry around\n# each of these origins will be used to updated the corresponding destination without deletion\n#          origin            destination
up_only=(\n          "archive/ebooks    ../share/ebooks"\n          "archive/music     ../share/music_giuse"\n          "archive/pictures  ../share/pics_giuse"\n          "archive/software  ../share/software"\n          "archive/videos    ../share/videos"\n          # QUICK HACK - android backup\n          "../../media/042F-1590  ../backup_android"\n        )\n
# And then of course there is plenty of folders you do not want to back up.\n# Caches, stuff you are backing up by other means, thumbnails...\n# Feel free anything that is slowing you down on a daily basis.\n#
# `exclusions` is a list of paths to exclude from backup\n#  - can use regular expressions\n#  - / at the beginning means start from the above declared origin\n#  - / at the end means "all directory content"\n#  - example: add "/.*/" to exclude all hidden directories in origin\n#  See man rsync page for a thorough reference\n\n
exclusions="\n  *.part\n  /exclude/\n  /Dropbox/\n  /.dropbox*/\n  .dropbox/\n  /.local/share/Trash/\n  /.rvm/\n  /.cache/\n  /.mozilla/\n  /.config/\n  /.local/\n  /.gconf/\n  /.gnome2/\n  /.thumbnails/\n  /.xsession*\n  /.gvfs/\n  /.wine/\n"\n
'
  echo -e "${conf}" > "${conf_file}"
}


# Execution control
main() {
  intro         # Initialization and intro
  load_conf     # Check if the config file is present, and if not write it
  set_dest      # Set destination variables: srv, srvp, path
  pre_call      # Set system variables based on configuration
  rsync_uponly  # rsync main call: backup main folder, propagate deletions, use exclusion list
  rsync_main    # rsync up-only calls: upload from folder list, no deletions, no exclusion list
  post_main     # Round up after the main call
  print_time    # Calculate the total time and print some stats
}


# Actual call
main

# TODO NEXT:
# - add server user name to configuration
# - add username to ssh calls: dests need to be either path or srv port user path
# - cli parser
# - verify writing permissions on destination directory d rwx r-x --- # ${rcmd} mkdir -p -m 750 "${path}"
# - load_conf implementation
# - notification popup of starting + result of backup
# - cron integration
# - function to restore a folder (works also for full backup)
# - write backup conf depending on GUI choices
# - create file for rsync exclusions, use it, back it up, then delete it
