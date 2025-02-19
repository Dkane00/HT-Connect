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
read -p "rfcomm number: " rfcomm_num

rfcomm_dev="/dev/rfcomm$rfcomm_num"

# Extract the MAC address of the selected rfcomm device
mac_addr=$(echo "$rfcomm_info" | grep "rfcomm$rfcomm_num" | awk '{print $2}')

# Validate that the selected rfcomm device is actually connected
if [ -z "$mac_addr" ]; then
    echo -e "\033[31mError: $rfcomm_dev is not currently connected.\033[0m"
    exit 1
fi

# Unbind the selected rfcomm device
echo "Releasing $rfcomm_dev..."
sudo rfcomm release "$rfcomm_num"

# Verify that the RFCOMM device has been disconnected
if ! rfcomm | grep -q "rfcomm$rfcomm_num"; then
    echo -e "\033[32mSuccess! $rfcomm_dev has been disconnected.\033[0m"
else
    echo -e "\033[31mError: Failed to disconnect $rfcomm_dev.\033[0m"
fi

# Fully disconnect the Bluetooth device while keeping it paired
echo "Disconnecting from Bluetooth device $mac_addr..."
echo -e "disconnect $mac_addr\nexit" | bluetoothctl

# Confirm disconnection
if bluetoothctl info "$mac_addr" | grep -q "Connected: yes"; then
    echo -e "\033[31mError: The device is still connected.\033[0m"
else
    echo -e "\033[32mSuccess! The Bluetooth device $mac_addr has been fully disconnected but remains paired.\033[0m"
fi

# Ask the user if they want to turn off Bluetooth
echo -e "\n\033[33mWould you like to turn off Bluetooth? \033[0m"
echo -e "\033[33m1. Turn off Bluetooth\033[0m"
echo -e "\033[33m2. Leave Bluetooth on\033[0m"
read -p "Enter your choice (1 or 2): " bt_choice

case $bt_choice in
    1)
        echo "Turning off Bluetooth..."
        sudo rfkill block bluetooth
        echo -e "\033[32mBluetooth has been turned off.\033[0m"
        ;;
    2)
        echo "Bluetooth will remain on."
        ;;
    *)
        echo -e "\033[31mInvalid choice. Bluetooth remains on.\033[0m"
        ;;
esac

exit 0
