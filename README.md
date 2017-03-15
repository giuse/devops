A bunch of scripts to support working on a computer.

## `quick_swap.sh`

#### Switches your swap to a newly created swapfile, then deletes it when you're done.

This is particularly useful if for example you're stuck with a small, slow (crypted) swap partition, but your hungry programs need more. The script creates a swap file of arbitrary size on your file system, swaps it on, then swaps off your previous swap partition. Then it waits; hit return to switch back to the swap partition, and use `shred` to ensure a safe swap file removal.

## `rbackup.sh`

#### Incremental backups (`rsync`-based) to custom server, using fastest access available.

My old rsync-based backup utility. Haven't touched this in a while, trying the likes of `duplicity` and `deja-dup`. I am going to switch back to this soon, it is much easier to control and configure. Plus, it accesses the backup location through the fastest access available (be it a hard-drive connected to your client, a server on your local net, or a server on the Internet).

It is intended to work with in-clear copies of your directories, to be stored on a crypted drive, using hard-links for extra transparency. The result is that, once the crypted drive is mounted, you can access backups from any date as if locally restored. This allows you to simply explore, verify, and pick and choose past versions of your data, all through your file manager of choice.

## `rbackup.rb`

#### Reimplementation of `rbackup.sh` using Ruby

Shell scripts are not ideal for complex projects, and my `rbackup.sh` has hit the limit. I'm going to port it to Ruby for readability and maintainability. WORK IN PROGRESS: I just barely sketched it out.

## `pair_ssh_keys.sh`

#### Set up a per-server and per-client key-pair for ssh key-based authentication.

I recently read an article which changed my mindset from "my ssh key is my ID and should uniquely identify me on all servers", to "an ID with no picture is easy to mess up with, better keep my keys separated and change them often".

I apply the same concept as password management: a different one for each server, and a password manager to handle the complexity. This script is a quick-setupper (is that even a word?) for the password manager that is `ssh-agent`.

Make sure you manually deactivate the no-passphrase option in `ssh-keygen` for added safety (I take my own measures, as I hate typing passphrases each time I contact a remote).

## `crypt_setup.sh`

#### Prepare a key-accessed encrypted partition on your system.

This is how I prepare a partition to unlock and mount by hand, where I store my backups.

I keep the encryption key in a safe place, such as a (itself encrypted) usb stick or network storage.
