#!/bin/bash

# Check if any rfcomm devices are currently connected
rfcomm_info=$(rfcomm)

if [ -z "$rfcomm_info" ]; then
    echo -e "\033[31mNo Bluetooth devices are currently connected.\033[0m"
    exit 1
fi

# Display connected devices
echo -e "\033[33mCurrently connected Bluetooth devices:\033[0m"
echo "$rfcomm_info"

# Prompt user to select which device to disconnect
echo -e "\n\033[33mEnter the rfcomm device number to disconnect (e.g., 0 for /dev/rfcomm0):\033[0m"
read -p "rfcomm" rfcomm_num

rfcomm_dev="/dev/rfcomm$rfcomm_num"

# Check if the selected rfcomm device is valid
if ! echo "$rfcomm_info" | grep -q "$rfcomm_dev"; then
    echo -e "\033[31mError: $rfcomm_dev is not currently connected.\033[0m"
    exit 1
fi

# Unbind the selected rfcomm device
sudo rfcomm release "$rfcomm_dev"

# Verify that the device has been disconnected
if ! rfcomm | grep -q "$rfcomm_dev"; then
    echo -e "\033[32mSuccess! $rfcomm_dev has been disconnected.\033[0m"
else
    echo -e "\033[31mError: Failed to disconnect $rfcomm_dev.\033[0m"
fi

exit 0
