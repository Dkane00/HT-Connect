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

    # Convert devices list to format for yad dropdown (Device Name first, then MAC Address)
    DEVICES_LIST=""
    while read -r line; do
        mac=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | cut -d ' ' -f3-)
        DEVICES_LIST+="$name ($mac)!"
    done <<< "$scan_results"

    # Remove trailing "!" from the list
    DEVICES_LIST="${DEVICES_LIST%!}"

    # Show devices in a drop-down menu
    SELECTED_DEVICE=$(yad --center --width=400 --title="Select Bluetooth Device" --form \
        --field="Devices:CB" "$DEVICES_LIST" --button="Pair:0" --button="Cancel:1")

    # Extract the selected MAC address
    mac_addr=$(echo "$SELECTED_DEVICE" | awk -F '[()]' '{print $2}')

    # Exit if no device is selected
    if [ -z "$mac_addr" ]; then
        exit 1
    fi

    bluetoothctl pair "$mac_addr"
    bluetoothctl trust "$mac_addr"

    # Extract values safely
    selected_device="${device_map[$choice]}"
    device_name=$(echo "$selected_device" | cut -d' ' -f2-)
    mac_addr=$(echo "$selected_device" | awk '{print $1}')

    if bluetoothctl info "$mac_addr" | grep -q "Paired: yes"; then
        yad --title="Success" --text="Successfully paired with $device_name ($mac_addr)." \
            --button="OK" --center --width=500 --height=200
    else
        yad --title="Error" --text="Failed to pair with $device_name ($mac_addr)." \
            --button="OK" --center --width=500 --height=200
    fi

    bluetoothctl connect "$mac_addr"
    if bluetoothctl info "$mac_addr" | grep -q "Connected: yes"; then
        yad --title="Success" --text="Successfully connected to $device_name ($mac_addr)." \
            --button="OK" --center --width=500 --height=200
    else
        yad --title="Error" --text="Failed to connect to $device_name ($mac_addr)." \
            --button="OK" --center --width=500 --height=200
    fi

    sleep 5
    bluetoothctl disconnect "$mac_addr"
    if bluetoothctl info "$mac_addr" | grep -q "Connected: no"; then
        yad --title="Success" --text="Successfully disconnected from $device_name ($mac_addr)." \
            --button="OK" --center --width=500 --height=200
    else
        yad --title="Warning" --text="Device $device_name ($mac_addr) may still be connected." \
            --button="OK" --center --width=500 --height=200
    fi


    yad --title="Success" --text="Your HT is now ready to connect." --button="OK" --center
}

# Main GUI
pair_bluetooth