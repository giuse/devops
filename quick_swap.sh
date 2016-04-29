#!/bin/bash
# Swap performance optimizer
#
# Sometimes you need PLENTY of EFFICIENT swap for a short period.
# In that case, the secure cryptoswap is going to cost you too much.
# This utility create an uncrypted, large, fast swapfile, deactivating
# the crypted swap, allowing you to safely crunch your data.
# When you are done, just hit return and the original configuration
# is restored, while the swapfile is securely shredded.

# on
echo "Creating swapfile"
sudo fallocate -l 32G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
echo "Switching swap"
sudo swapon /swapfile
sudo swapoff /dev/mapper/cryptswap1
echo "  done!"
echo
sudo swapon -s
echo

# ready
echo "Quick swap on, enjoy"
echo "Once done, press 'ENTER' to roll back"
read kthxbye
echo

# off
echo "Switching back swap"
sudo swapon /dev/mapper/cryptswap1
sudo swapoff /swapfile
echo "Schredding swapfile"
echo "(feel free to interrupt this if you didn't"
echo "  actually get to use the swap)"
sudo shred -uvzn 0 /swapfile
echo
echo "Removing swapfile"
sudo rm /swapfile
echo "  done!"
echo
sudo swapon -s
echo
