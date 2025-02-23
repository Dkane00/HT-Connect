#!/bin/bash

# Color text for menus
YELLOW='\e[33m'
GREEN='\e[32m'
RED='\e[31m'
NC='\e[0m'

# Check if the user has sudo permissions
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

# Function to turn Bluetooth on
turn_bluetooth_on() {
    echo "Turning Bluetooth on..."
    sudo rfkill unblock bluetooth
    sleep 2 # Give Bluetooth a moment to initialize
}

# Check if Bluetooth is turned on
if rfkill list bluetooth | grep -q "Soft blocked: yes"; then
    echo -e "${YELLOW}Bluetooth is currently turned off.${NC}"
    echo -e "${YELLOW}1. Turn on Bluetooth${NC}"
    echo -e "${YELLOW}2. Leave Bluetooth off and exit${NC}"
    read -p "Enter your choice (1 or 2): " choice
    
    case $choice in
        1) turn_bluetooth_on ;;
        2) echo "Bluetooth remains off. Exiting."; exit 1 ;;
        *) echo "Invalid choice. Exiting."; exit 1 ;;
    esac
fi

# Start scanning for Bluetooth devices
echo -e "${YELLOW}Scanning for Bluetooth devices...${NC}"
bluetoothctl scan on &
scan_pid=$!

# Allow scanning to run for a few seconds
sleep 10  

# Stop scanning
echo -e "${YELLOW}Stopping Bluetooth scan...${NC}"
if ! bluetoothctl scan off; then
    echo -e "${RED}Scan off command failed. Killing scan process...${NC}"
    sudo pkill -f "bluetoothctl scan on"
fi

# Get list of available devices
scan_results=$(bluetoothctl devices)

# Check if any devices were found
if [ -z "$scan_results" ]; then
    echo -e "${RED}No Bluetooth devices found.${NC}"
    exit 1
fi

# Display the results in a numbered menu
echo -e "${YELLOW}Discovered Bluetooth devices:${NC}"
index=1
declare -A device_map

while read -r line; do
    mac=$(echo "$line" | awk '{print $2}')
    name=$(echo "$line" | cut -d ' ' -f3-)
    device_map[$index]="$mac $name"
    printf "${GREEN}%d. %s (%s)${NC}\n" "$index" "$name" "$mac"
    ((index++))
done <<< "$scan_results"

echo -e "${YELLOW}==============================${NC}"
read -p "Enter the number of the device you want to connect to: " choice

if [[ -z "${device_map[$choice]}" ]]; then
    echo -e "${RED}Invalid selection.${NC}"
    exit 1
fi

mac_addr=$(echo "${device_map[$choice]}" | awk '{print $1}')
device_name=$(echo "${device_map[$choice]}" | cut -d ' ' -f2-)

# Check if the device is already paired
if bluetoothctl paired-devices | grep -q "$mac_addr"; then
    echo -e "${GREEN}Device '$device_name' ($mac_addr) is already paired.${NC}"
else
    echo "Pairing with '$device_name' ($mac_addr)..."
    bluetoothctl pair "$mac_addr"
    bluetoothctl trust "$mac_addr"
fi

# Connect to the device
echo "Connecting to '$device_name' ($mac_addr)..."
bluetoothctl connect "$mac_addr"

# Give it a moment to establish the connection
sleep 5

# Find the next available RFCOMM device
rfcomm_index=0
while [ -e "/dev/rfcomm$rfcomm_index" ]; do
    ((rfcomm_index++))
done
rfcomm_device="/dev/rfcomm$rfcomm_index"

# Bind the device to RFCOMM
echo -e "${YELLOW}Binding device to RFCOMM: $rfcomm_device${NC}"
sudo rfcomm bind "$rfcomm_index" "$mac_addr"

# Verify RFCOMM binding
sleep 2
if ! rfcomm | grep -q "$rfcomm_device"; then
    echo -e "${RED}Error: Failed to bind RFCOMM device ($rfcomm_device).${NC}"
    sudo rfcomm release "$rfcomm_index"
    exit 1
fi

# Attach the RFCOMM device to kissattach
echo -e "${YELLOW}Attaching $rfcomm_device to kissattach as uvtnc1200...${NC}"
sudo kissattach "$rfcomm_device" uvtnc1200

# Verify kissattach setup
sleep 2
if ifconfig | grep -q "uvtnc1200"; then
    echo -e "${GREEN}Success! Your device '$device_name' ($mac_addr) is now connected as uvtnc1200.${NC}"
    echo "You can now communicate with your KISS TNC using the uvtnc1200 interface."
else
    echo -e "${RED}Error: Failed to attach RFCOMM device to kissattach.${NC}"
    sudo rfcomm release "$rfcomm_index"
    exit 1
fi

# Exit the script, leaving the connection active
exit 0