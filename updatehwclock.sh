#!/bin/bash

# Check if ntpdate is installed
if ! command -v ntpdate &> /dev/null
then
    echo "ntpdate could not be found. Please install it using 'sudo apt install ntpdate' (on Debian/Ubuntu) or 'sudo yum install ntpdate' (on CentOS/RHEL)."
    exit 1
fi

# Define UK-based NTP server
NTP_SERVER="0.uk.pool.ntp.org"

# Sync system clock with the NTP server
echo "Syncing system clock with NTP server ($NTP_SERVER)..."
sudo ntpdate -u $NTP_SERVER

# Check if the system clock update was successful
if [ $? -ne 0 ]; then
    echo "Failed to sync with NTP server. Please check your internet connection or the NTP server address."
    exit 1
else
    echo "System clock successfully updated."
fi

# Set hardware clock to match system clock
echo "Syncing hardware clock with system clock..."
sudo hwclock --systohc

# Verify the hardware clock sync
if [ $? -eq 0 ]; then
    echo "Hardware clock successfully synced with system clock."
else
    echo "Failed to sync hardware clock with system clock."
    exit 1
fi

echo "Time synchronization complete."
