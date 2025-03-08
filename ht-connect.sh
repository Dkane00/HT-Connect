#!/bin/bash

# Function to run a script with sudo password prompt
run_script() {
    local script=$1
    local title=$2
    # Prompt for sudo password and run the script
    password=$(yad --title="$title" --form --field="Enter sudo password:H" --button="OK" | awk -F'|' '{print $1}')
    echo "$password" | sudo -S bash "$script"
}

# Export the function definition so it can be used in subshells
export -f run_script

# Create the main GUI window
yad --title="Script Launcher" --form \
    --field="Connect Bluetooth:BTN" "bash -c 'source $0; run_script connect.sh \"Connect Bluetooth\"'" \
    --field="Disconnect Bluetooth:BTN" "bash -c 'source $0; run_script disconnect.sh \"Disconnect Bluetooth\"'" \
    --field="KISS Connect:BTN" "bash -c 'source $0; run_script kiss-connect.sh \"KISS Connect\"'" \
    --field="Pairing:BTN" "bash -c 'source $0; run_script pairing.sh \"Pairing\"'" \
    --field="TCP Connect:BTN" "bash -c 'source $0; run_script tcp-connect.sh \"TCP Connect\"'" \
    --button="Exit" --width=400 --height=300