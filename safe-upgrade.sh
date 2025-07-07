#!/bin/bash
# safe-upgrade.sh
# Description: Helps you update packages in small, reviewable segments.
# Compatible with Termux and Debian/Ubuntu Linux.
# Author: YourGitHubUsername
# GitHub: https://github.com/YourUsername/safe-upgrade

set -e

# Detect if running in Termux or Linux
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

# Ask for segment size
while ! [[ "$SEGMENT_SIZE" =~ ^[0-9]+$ ]]; do
    read -p "Enter the number of packages per segment (must be a number): " SEGMENT_SIZE
done

# Clean up old files
rm -f package_segment_* install_package_segment_*.sh

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
