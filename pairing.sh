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

# Prompt user to ensure HT is in pairing mode
echo -e "${YELLOW}Make sure that your HT is in pairing mode if you have never paired the HT with this device.${NC}"
echo -e "${YELLOW}1. My HT is Ready, Proceed${NC}"
echo -e "${YELLOW}2. Exit${NC}"
read -p "Enter your choice (1 or 2): " pairing_choice

case $pairing_choice in
    1) echo "Proceeding with Bluetooth setup..." ;;
    2) echo "Exiting. Please put your HT in pairing mode and restart the script."; exit 1 ;;
    *) echo "Invalid choice. Exiting."; exit 1 ;;
esac

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

# Start scanning for Bluetooth devices
echo -e "${YELLOW}Scanning for Bluetooth devices...${NC}"
bluetoothctl scan on &
scan_pid=$!
sleep 10  # Allow scanning to run

# Stop scanning
echo -e "${YELLOW}Stopping Bluetooth scan...${NC}"
bluetoothctl scan off || sudo pkill -f "bluetoothctl scan on"

# Get list of available devices
scan_results=$(bluetoothctl devices)
if [ -z "$scan_results" ]; then
    echo -e "${RED}No Bluetooth devices found.${NC}"
    exit 1
fi

# Display the results
declare -A device_map
index=1
while read -r line; do
    mac=$(echo "$line" | awk '{print $2}')
    name=$(echo "$line" | cut -d ' ' -f3-)
    device_map[$index]="$mac $name"
    printf "${GREEN}%d. %s (%s)${NC}\n" "$index" "$name" "$mac"
    ((index++))
done <<< "$scan_results"

echo -e "${YELLOW}==============================${NC}"
read -p "Enter the number of the device you want to pair: " choice

if [[ -z "${device_map[$choice]}" ]]; then
    echo -e "${RED}Invalid selection.${NC}"
    exit 1
fi

# Get the selected MAC address
mac_addr=$(echo "${device_map[$choice]}" | awk '{print $1}')

# Pair the device
echo -e "${YELLOW}Pairing with $mac_addr...${NC}"
bluetoothctl pair "$mac_addr"

# Trust the device
echo -e "${YELLOW}Setting $mac_addr as trusted...${NC}"
bluetoothctl trust "$mac_addr"

# Verify pairing status
if bluetoothctl info "$mac_addr" | grep -q "Paired: yes"; then
    echo -e "${GREEN}Successfully paired with ${device_map[$choice]}${NC}"
else
    echo -e "${RED}Failed to pair with ${device_map[$choice]}.${NC}"
    exit 1
fi

# Connect to the Bluetooth device
echo -e "${YELLOW}Connecting to $mac_addr...${NC}"
bluetoothctl connect "$mac_addr"

# Check connection status
if bluetoothctl info "$mac_addr" | grep -q "Connected: yes"; then
    echo -e "${GREEN}Successfully connected to ${device_map[$choice]}${NC}"
else
    echo -e "${RED}Failed to connect to ${device_map[$choice]}.${NC}"
    exit 1
fi

sleep 5

# Disconnect the device
echo -e "${YELLOW}Disconnecting from $mac_addr...${NC}"
bluetoothctl disconnect "$mac_addr"

# Verify disconnection
if bluetoothctl info "$mac_addr" | grep -q "Connected: no"; then
    echo -e "${GREEN}Successfully disconnected from ${device_map[$choice]}${NC}"
else
    echo -e "${RED}Warning: Device ${device_map[$choice]} may still be connected.${NC}"
fi

# Final message
echo -e "${GREEN}Your HT is now ready to connect${NC}"

exit 0
