#!/bin/bash

# Color text for the menus
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

# Start scanning for Bluetooth devices
echo -e "${YELLOW}Scanning for Bluetooth devices...${NC}"
bluetoothctl scan on &
scan_pid=$!  # Store the scan process ID

# Allow scanning to run for a few seconds
sleep 10  

# Attempt to stop scanning
echo -e "${YELLOW}Stopping Bluetooth scan...${NC}"
if ! bluetoothctl scan off; then
    echo -e "${YELLOW}Scan off command failed. Killing the scan and moving on${NC}"
    sudo pkill -f "bluetoothctl scan on"
fi

# Get list of available devices
scan_results=$(bluetoothctl devices)

# Check if any devices were found
if [ -z "$scan_results" ]; then
    echo "No Bluetooth devices found."
    exit 1
fi

# Display the results in a numbered menu
echo -e "${YELLOW}Discovered Bluetooth devices:${NC}"
echo -e "${YELLOW}==============================${NC}"
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
    echo "Invalid selection."
    exit 1
fi

mac_addr=$(echo "${device_map[$choice]}" | awk '{print $1}')
device_name=$(echo "${device_map[$choice]}" | cut -d ' ' -f2-)

# Check if the device is already paired
if bluetoothctl paired-devices | grep -q "$mac_addr"; then
    echo -e "\033[32mDevice '$device_name' ($mac_addr) is already paired.\033[0m"
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

# Find the next available /dev/ttybt* device
bt_index=0
while [ -e "/dev/ttybt$bt_index" ]; do
    ((bt_index++))
done
bt_device="/dev/ttybt$bt_index"

# Set up a virtual serial port using socat
echo -e "${YELLOW}Creating virtual serial port at $bt_device using socat...${NC}"
sudo socat -d -d pty,raw,echo=0,link=$bt_device TCP-CONNECT:"$mac_addr":1 &

# Check if the virtual serial port was successfully created
sleep 2
if [ -e "$bt_device" ]; then
    echo -e "\033[32mSuccess! Your device '$device_name' ($mac_addr) is now connected to $bt_device.\033[0m"
    echo "You can now communicate with your Bluetooth device using this serial port."
else
    echo -e "\033[31mError: Failed to create virtual serial port for '$device_name' ($mac_addr). Please try again.\033[0m"
    exit 1
fi
