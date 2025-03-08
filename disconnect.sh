#!/bin/bash

# Colors for messages
YELLOW='\e[33m'
GREEN='\e[32m'
RED='\e[31m'
NC='\e[0m'

echo -e "${YELLOW}Stopping kissattach connection...${NC}"

# Find and kill the kissattach process
kissattach_pid=$(pgrep -f "kissattach /dev/rfcomm")

if [ -n "$kissattach_pid" ]; then
    sudo kill "$kissattach_pid"
    sleep 2  # Allow kissattach to terminate cleanly
    echo -e "${GREEN}Kissattach process stopped.${NC}"
else
    echo -e "${RED}No active kissattach connection found.${NC}"
fi

# Find and kill any running socat process
socat_pid=$(pgrep -f "socat -d tcp-listen:9100")

if [ -n "$socat_pid" ]; then
    echo -e "${YELLOW}Stopping socat process (PID: $socat_pid)...${NC}"
    sudo kill "$socat_pid"
    sleep 2
    echo -e "${GREEN}Socat process stopped.${NC}"
else
    echo -e "${RED}No active socat process found.${NC}"
fi

# Identify the connected Bluetooth device
connected_device=$(bluetoothctl info | grep "Device" | awk '{print $2}')

if [ -n "$connected_device" ]; then
    # Find the RFCOMM device bound to this Bluetooth MAC address
    rfcomm_device=$(rfcomm | grep "$connected_device" | awk '{print $1}')

    if [ -n "$rfcomm_device" ]; then
        echo -e "${YELLOW}Releasing RFCOMM binding for $rfcomm_device...${NC}"
        sudo rfcomm release "$rfcomm_device"
        sleep 1
        echo -e "${GREEN}RFCOMM binding released.${NC}"
    else
        echo -e "${RED}No active RFCOMM binding found for $connected_device.${NC}"
    fi

    echo -e "${YELLOW}Disconnecting Bluetooth device $connected_device...${NC}"
    echo -e "disconnect $connected_device\nexit" | bluetoothctl
    sleep 2

    # Confirm disconnection
    if bluetoothctl info "$connected_device" | grep -q "Connected: yes"; then
        echo -e "${RED}Error: The device is still connected.${NC}"
    else
        echo -e "${GREEN}Success! The Bluetooth device has been fully disconnected but remains paired.${NC}"
    fi
else
    echo -e "${RED}No connected Bluetooth device found.${NC}"
fi

# Ask the user if they want to turn off Bluetooth
echo -e "\n${YELLOW}Would you like to turn off Bluetooth?${NC}"
echo -e "${YELLOW}1. Turn off Bluetooth${NC}"
echo -e "${YELLOW}2. Leave Bluetooth on${NC}"
read -p "Enter your choice (1 or 2): " bt_choice

case $bt_choice in
    1)
        echo "Turning off Bluetooth..."
        sudo rfkill block bluetooth
        echo -e "${GREEN}Bluetooth has been turned off.${NC}"
        ;;
    2)
        echo "Bluetooth will remain on."
        ;;
    *)
        echo -e "${RED}Invalid choice. Bluetooth remains on.${NC}"
        ;;
esac

exit 0
