#!/bin/bash

# Colors for messages
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

# Search for paired devices matching the criteria
echo -e "${YELLOW}Searching for paired HT's ...${NC}"
paired_devices=$(bluetoothctl paired-devices | grep -E 'UV-PRO|VR-N76|GA-5WB|TH-D74|TH-D75|VR-N7500')

# Check if any devices were found
if [ -z "$paired_devices" ]; then
    echo -e "${RED}Error: No paired HT's found with names 'UV-PRO','VR-N76','TH-D74','TH-D75','GA-5WB' or 'VR-N7500'.${NC}"
    exit 1
fi

# Convert paired devices into a menu selection format
device_list=()
while IFS= read -r line; do
    mac=$(echo "$line" | awk '{print $2}')
    name=$(echo "$line" | cut -d ' ' -f3-)
    device_list+=("$mac - $name")
done <<< "$paired_devices"

# Display a menu to select a device
echo -e "${YELLOW}Select a device to connect:${NC}"
select selection in "${device_list[@]}"; do
    if [[ -n "$selection" ]]; then
        mac_addr=$(echo "$selection" | awk '{print $1}')
        echo -e "${GREEN}You selected: $selection${NC}"
        break
    else
        echo -e "${RED}Invalid selection, please try again.${NC}"
    fi
done

# RFCOMM device index
rfcomm_index=0
rfcomm_device="/dev/rfcomm$rfcomm_index"
rfcomm_check="rfcomm$rfcomm_index"

# Release any existing RFCOMM binding
sudo rfcomm release "$rfcomm_index" 2>/dev/null

# Connect the Bluetooth device to RFCOMM in the background
echo -e "${YELLOW}Connecting device ($mac_addr) to RFCOMM: $rfcomm_device${NC}"
sudo nohup rfcomm connect "$rfcomm_index" "$mac_addr" 1 > /dev/null 2>&1 & disown

# Allow time for connection to establish
sleep 10

# Verify RFCOMM connection
if ! rfcomm | grep -q "$rfcomm_check"; then
    echo -e "${RED}Error: Failed to connect RFCOMM device ($rfcomm_device).${NC}"
    exit 1
fi

# Start socat to forward RFCOMM to TCP
TCP_PORT=9100
echo -e "${YELLOW}Starting socat to forward $rfcomm_device to TCP port $TCP_PORT...${NC}"
sudo nohup socat -d tcp-listen:$TCP_PORT,reuseaddr,fork file:$rfcomm_device,b115200,raw > /dev/null 2>&1 & disown

# Allow socat to initialize
sleep 2

# Verify socat process is running
if pgrep -f "socat -d tcp-listen:$TCP_PORT" > /dev/null; then
    echo -e "${GREEN}Success: RFCOMM device $rfcomm_device is now available on TCP port $TCP_PORT.${NC}"
else
    echo -e "${RED}Error: Socat failed to start.${NC}"
    exit 1
fi

exit 0
