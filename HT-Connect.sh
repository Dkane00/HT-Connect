#!/bin/bash

# color text for the menus
YELLOW='\e[33m'
GREEN='\e[32m'
NC='\e[0m'

# Check if the user has sudo permissions
if ! sudo -v &>/dev/null; then
    echo "Error: You need sudo permissions to run this script."
    exit 1
fi

# Prompt user to ensure HT is in pairing mode
echo -e "${YELLOW}Make sure that your HT is in pairing mode if you have never paired the HT with this device.${NC}"
echo -e "${YELLOW}1. My HT is Ready, Proceed${NC}"
echo -e "${YELLOW}2. Exit${NC}"
read -p "Enter your choice (1 or 2): " pairing_choice

case $pairing_choice in
    1)
        echo "Proceeding with Bluetooth setup..."
        ;;
    2)
        echo "Exiting. Please put your HT in pairing mode and restart the script."
        exit 1
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Function to turn Bluetooth on
turn_bluetooth_on() {
    echo "Turning Bluetooth on..."
    sudo rfkill unblock bluetooth
    sleep 2 # Give Bluetooth a moment to initialize
}

# Check if Bluetooth is turned on
bluetooth_status=$(rfkill list bluetooth | grep "Soft blocked: yes")
if [ -n "$bluetooth_status" ]; then
    echo -e "${YELLOW}Bluetooth is currently turned off.${NC}"
    echo -e "${YELLOW}Would you like to turn Bluetooth on?${NC}"
    echo -e "${YELLOW}1. Turn on Bluetooth${NC}"
    echo -e "${YELLOW}2. Leave Bluetooth off and exit${NC}"
    read -p "Enter your choice (1 or 2): " choice
    
    case $choice in
        1)
            turn_bluetooth_on
            ;;
        2)
            echo "Bluetooth remains off. Exiting."
            exit 1
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

# Run hcitool scan and store the results in a variable
echo -e "${YELLOW}Scanning for Bluetooth devices...${NC}"
scan_results=$(hcitool scan)

# Check if any devices were found
if [ -z "$scan_results" ]; then
    echo "No Bluetooth devices found."
    exit 1
fi

# Display the results in a numbered menu
echo -e "${YELLOW}Discovered Bluetooth devices:${NC}"
echo -e "${YELLOW}==============================${NC}"
# Use awk to format the output with numbers in green, skipping the header line
echo "$scan_results" | awk -v green="$GREEN" -v nc="$NC" 'NR>1 {print green NR-1 ". " $3 nc}'

echo -e "${YELLOW}==============================${NC}"
read -p "Enter the number of the device you want to connect to: " choice

device_info=$(echo "$scan_results" | awk -v choice="$choice" 'NR==choice+1 {print $2, $3}')
mac_addr=$(echo "$device_info" | awk '{print $1}')
device_name=$(echo "$device_info" | awk '{print $2}')

if [ -z "$mac_addr" ]; then
    echo "Invalid selection."
    exit 1
fi

echo "Connecting to '$device_name' ($mac_addr)..."
sudo rfcomm connect /dev/rfcomm0 "$mac_addr"
