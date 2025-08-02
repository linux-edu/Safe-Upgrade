#!/bin/bash
# safe-upgrade.sh
# Description: Helps you update packages in small, reviewable segments.
# Compatible with Termux and Debian/Ubuntu Linux.
# Author: linux-edu
# GitHub: https://github.com/linux-edu/Safe-Upgrade

set -e

# 🧹 Ask to clean old temporary files
if ls upgradable_packages.txt package_segment_* install_package_segment_*.sh 1>/dev/null 2>&1; then
    echo "Previous temporary files found."
    read -p "Do you want to clean up old segment files from a previous run? [y/N]: " PRE_CLEAN
    if [[ "$PRE_CLEAN" =~ ^[Yy]$ ]]; then
        rm -f upgradable_packages.txt package_segment_* install_package_segment_*.sh
        echo "Old files removed."
    else
        echo "Old files kept. Continuing..."
    fi
fi

# 🧠 Detect Termux or Linux
if command -v termux-info >/dev/null 2>&1; then
    APT_CMD="apt"
else
    APT_CMD="sudo apt"
fi

echo "Running $APT_CMD update..."
$APT_CMD update

echo "Generating list of upgradable packages..."
$APT_CMD list --upgradable | awk -F/ 'NR>1 {print $1}' > upgradable_packages.txt

if [ ! -s upgradable_packages.txt ]; then
    echo "No upgradable packages found."
    exit 0
fi

# 🧩 Ask for segment size
while ! [[ "$SEGMENT_SIZE" =~ ^[0-9]+$ ]]; do
    read -p "Enter the number of packages per segment (must be a number): " SEGMENT_SIZE
done

echo "Splitting the list into segments of $SEGMENT_SIZE packages..."
split -l "$SEGMENT_SIZE" upgradable_packages.txt package_segment_

echo "Creating install scripts for each segment..."
for file in package_segment_*; do
    echo "$APT_CMD install -y $(tr '\n' ' ' < "$file")" > install_$file.sh
    chmod +x install_$file.sh
done

echo "Segments and scripts created:"
ls install_package_segment_*

echo "To install packages, run the generated scripts, e.g.:"
echo "./install_package_segment_aa.sh"

