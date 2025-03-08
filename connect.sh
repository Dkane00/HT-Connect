#!/bin/bash

# Color text for messages
YELLOW='\e[33m'
GREEN='\e[32m'
RED='\e[31m'
NC='\e[0m'

# Ensure sudo permissions
if ! sudo -v &>/dev/null; then
    echo -e "${RED}Error: You need sudo permissions to run this script.${NC}"
    exit 1
fi

# Check if Bluetooth is turned off
if rfkill list bluetooth | grep -q "Soft blocked: yes"; then
    echo -e "${YELLOW}Bluetooth is currently turned off.${NC}"
    echo -e "${YELLOW}1. Turn on Bluetooth${NC}"
    echo -e "${YELLOW}2. Exit without turning on Bluetooth${NC}"
    read -p "Enter your choice (1 or 2): " choice
    
    case $choice in
        1) 
            echo -e "${YELLOW}Turning on Bluetooth...${NC}"
            sudo rfkill unblock bluetooth
            sleep 2 
            ;;
        2) 
            echo -e "${RED}Bluetooth remains off. Exiting.${NC}"
            exit 1 
            ;;
        *) 
            echo -e "${RED}Invalid choice. Exiting.${NC}"
            exit 1 
            ;;
    esac
fi

# Search for paired devices matching 'UV-PRO' or 'VN76'
echo -e "${YELLOW}Searching for paired devices named 'UV-PRO' or 'VN76'...${NC}"
paired_devices=$(bluetoothctl paired-devices | grep -E 'UV-PRO|VN76')

# Check if any devices were found
if [ -z "$paired_devices" ]; then
    echo -e "${RED}Error: No paired devices found with names 'UV-PRO' or 'VN76'.${NC}"
    exit 1
fi

# Extract the MAC address of the first matching device
mac_addr=$(echo "$paired_devices" | awk '{print $2}' | head -n 1)

# Display the selected device
echo -e "${GREEN}Found device: $(echo "$paired_devices" | head -n 1)${NC}"

# RFCOMM device index
rfcomm_index=0
rfcomm_device="/dev/rfcomm$rfcomm_index"
rfcomm_check="rfcomm$rfcomm_index"

# Release any existing RFCOMM binding
sudo rfcomm release "$rfcomm_index" 2>/dev/null

# Connect the Bluetooth device to RFCOMM in the background
echo -e "${YELLOW}Connecting device ($mac_addr) to RFCOMM: $rfcomm_device${NC}"
sudo nohup rfcomm connect "$rfcomm_index" "$mac_addr" &> nohup_rfcomm.log & disown

# Allow time for connection to establish
sleep 10

# Verify RFCOMM connection
if ! rfcomm | grep -q "$rfcomm_check"; then
    echo -e "${RED}Error: Failed to connect RFCOMM device ($rfcomm_device).${NC}"
    exit 1
fi

# Success message
echo -e "${GREEN}Success: Device $mac_addr is now connected to $rfcomm_device.${NC}"
exit 0
