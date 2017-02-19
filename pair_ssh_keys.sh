#!/bin/bash
# Set up a per-server and per-client key-pair for ssh key-based authentication

# I recently read an article which changed my mindset from "my ssh key is my ID
# and should uniquely identify me on all servers", to "an ID with no picture is
# easy to mess up with, better keep my keys separated and change them often".

# Same concept as password management: one different for each server, and a
# password manager to handle the complexity. This script is a quick-setupper
# for the password manager that is `ssh-agent`.

# NOTE: an empty passphrase here is only slightly safer than usual, as each key
# pair is effectively throw-away and accesses only one client/server connection.
# I do NOT recommend this. I personally cope with the risk by means of other,
# external measures. A strong passphrase is usually the way to go.
# For increased safety, do please feel free to comment the `-N ""` bit on the
# `ssh-keygen` command.

# args check
if [ "$#" != 4 ]; then
  echo -e "\nUSAGE: $(basename "$0") <server_name> <server_ip> <server_port> <user_name>"
  echo -e "\nwhere:"
  echo -e "\t<server_name>:  name the server (e.g. for 'ssh <server_name>')"
  echo -e "\t<server_ip>:    server ip address (DNS names may work too)"
  echo -e "\t<server_port>:  server ssh port (by default should be 22)"
  echo -e "\t<user_name>:    user name on server to use for login"
  exit 1
fi

# configuration (no need for `shift`)
SERVER_NAME="$1"  # cluster
SERVER_IP="$2"    # 192.168.1.100
SERVER_PORT="$3"  # 22
USER_NAME="$4"    # giuse

# abort if <server_name> already present in config
if [ -f "${HOME}/.ssh/config" ]; then # more readable with two `if`s than `-a \<newline>`
  if grep -v "HostName" "${HOME}/.ssh/config" | grep "Host ${SERVER_NAME}" > /dev/null; then
    echo "ABORT: '.ssh/config' has already an entry for server '${SERVER_NAME}'"
    exit 1
  fi
fi

# setup
mkdir -p "${HOME}/.ssh/"
KEY_NAME="${HOME}/.ssh/${SERVER_NAME}"

# add basic server info into `config`
echo -e "\nHost ${SERVER_NAME}\n\tHostName ${SERVER_IP}\n\tPort ${SERVER_PORT}
\tUser ${USER_NAME}\n\tIdentityFile ${KEY_NAME}" >> "${HOME}/.ssh/config"

# generate key -- quiet and no passphrase (BEWARE)
ssh-keygen -t rsa -b 4096 -C "$(whoami)@$(hostname)" -f "${KEY_NAME}" -q -N ""
# make sure ssh-agent is up and add the new key
eval "$(ssh-agent -s)"
ssh-add "${KEY_NAME}"

# send public key over to server
ssh-copy-id -i "${KEY_NAME}.pub" "${USER_NAME}@${SERVER_IP}"

echo -e "All done!"
echo -e "You may want to check out '.ssh/config' and further"
echo -e "customize your new '${SERVER_NAME}' server entry."
