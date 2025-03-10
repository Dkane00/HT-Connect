#!/bin/bash

# Function to pair a Bluetooth device
pair_bluetooth() {
    yad --title="Pairing" --text="Make sure that your HT is in pairing mode if you have never paired the HT with this device." \
        --field="1. My HT is Ready, Proceed:BTN" --field="2. Exit:BTN" --button="OK" --center
    case $choice in
        1*) ;;
        2*) return ;;
    esac

    # Function to check Bluetooth status and prompt user
check_bluetooth() {
    if ! rfkill list bluetooth | grep -q "Soft blocked: no"; then
        yad --center --width=300 --height=150 --title="Bluetooth Off" --button="Turn On:0" --button="Exit:1" --text="Bluetooth is off.\nWould you like to turn it on?"
        choice=$?
        
        if [ "$choice" -eq 0 ]; then
            rfkill unblock bluetooth
            sleep 5
        else
            yad --center --width=300 --height=100 --title="Exiting" --text="Bluetooth must be on to continue." --button="OK:0"
            exit 1
        fi
    fi
}

# Run Bluetooth check
check_bluetooth
    
    bluetoothctl scan on &
    scan_pid=$!
    sleep 10
    bluetoothctl scan off || sudo pkill -f "bluetoothctl scan on"

    scan_results=$(bluetoothctl devices)
    if [ -z "$scan_results" ]; then
        yad --title="Error" --text="No Bluetooth devices found." --button="OK" --center
        return
    fi

    declare -A device_map
    index=1
    while read -r line; do
        mac=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | cut -d ' ' -f3-)
        device_map[$index]="$mac $name"
        printf "${GREEN}%d. %s (%s)${NC}\n" "$index" "$name" "$mac"
        ((index++))
    done <<< "$scan_results"

    choice=$(yad --title="Select Device" --form --text="Select the device you want to pair:" \
        --field="Device:CB" "$(for key in "${!device_map[@]}"; do echo "$key. ${device_map[$key]}"; done)" --button="OK" --center)
    mac_addr=$(echo "${device_map[$choice]}" | awk '{print $1}')

    bluetoothctl pair "$mac_addr"
    bluetoothctl trust "$mac_addr"

    if bluetoothctl info "$mac_addr" | grep -q "Paired: yes"; then
        yad --title="Success" --text="Successfully paired with ${device_map[$choice]}." --button="OK" --center
    else
        yad --title="Error" --text="Failed to pair with ${device_map[$choice]}." --button="OK" --center
    fi

    bluetoothctl connect "$mac_addr"
    if bluetoothctl info "$mac_addr" | grep -q "Connected: yes"; then
        yad --title="Success" --text="Successfully connected to ${device_map[$choice]}." --button="OK" --center
    else
        yad --title="Error" --text="Failed to connect to ${device_map[$choice]}." --button="OK" --center
    fi

    sleep 5
    bluetoothctl disconnect "$mac_addr"
    if bluetoothctl info "$mac_addr" | grep -q "Connected: no"; then
        yad --title="Success" --text="Successfully disconnected from ${device_map[$choice]}." --button="OK" --center
    else
        yad --title="Warning" --text="Device ${device_map[$choice]} may still be connected." --button="OK" --center
    fi

    yad --title="Success" --text="Your HT is now ready to connect." --button="OK" --center
}

# Main GUI
pair_bluetooth