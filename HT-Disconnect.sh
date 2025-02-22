#!/bin/bash

# Find and kill the socat process
socat_pid=$(pgrep -f "socat -d -d pty,raw,echo=0,link=/tmp/bluetooth-serial")

if [ -n "$socat_pid" ]; then
    echo -e "\033[33mStopping socat connection...\033[0m"
    sudo kill "$socat_pid"
    sleep 2  # Give it a moment to fully terminate
else
    echo -e "\033[31mNo active socat connection found.\033[0m"
fi

# Identify the connected Bluetooth device
connected_device=$(bluetoothctl info | grep "Device" | awk '{print $2}')

if [ -n "$connected_device" ]; then
    echo -e "\033[33mDisconnecting Bluetooth device $connected_device...\033[0m"
    echo -e "disconnect $connected_device\nexit" | bluetoothctl
    sleep 2
else
    echo -e "\033[31mNo connected Bluetooth device found.\033[0m"
fi

# Confirm disconnection
if bluetoothctl info "$connected_device" | grep -q "Connected: yes"; then
    echo -e "\033[31mError: The device is still connected.\033[0m"
else
    echo -e "\033[32mSuccess! The Bluetooth device has been fully disconnected but remains paired.\033[0m"
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
