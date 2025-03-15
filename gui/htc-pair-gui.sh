#!/bin/bash

# Function to pair a Bluetooth device
pair_bluetooth() {
    yad --title="Pairing" --text="Make sure that your HT is in pairing mode \nSelect OK when ready to pair the HT with this device." \
        --button="My HT is Ready, Proceed":0 --button="Exit":1 --center --width=500 --height=100
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
    
    yad --title="Scanning" --text="Scanning for Bluetooth Devices" --text-align=center --center --width=500 --height=100 &
    YAD_PID=$!

    bluetoothctl scan on &
    scan_pid=$!
    sleep 10
    bluetoothctl scan off || sudo pkill -f "bluetoothctl scan on"

    kill $YAD_PID

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
    SELECTED_DEVICE=$(yad --center --width=500 --height=100 --title="Select Bluetooth Device" --form \
        --field="Devices:CB" "$DEVICES_LIST" --button="Pair:0" --button="Cancel:1")

    # Extract the selected MAC address
    mac_addr=$(echo "$SELECTED_DEVICE" | awk -F '[()]' '{print $2}')

    # Exit if no device is selected
    if [ -z "$mac_addr" ]; then
        exit 1
    fi

    yad --title="Pairing" --text="Pairing $SELECTED_DEVICE" --text-align=center --center --width=500 --height=100 &
    YAD_PID=$!

    bluetoothctl pair "$mac_addr"
    bluetoothctl trust "$mac_addr"

    sleep 2
    kill $YAD_PID


    if bluetoothctl info "$mac_addr" | grep -q "Paired: yes"; then
        yad --title="Success" --text="Successfully paired with $SELECTED_DEVICE." --text-align=center \
            --center --width=500 --height=100 &
        YAD_PID=$!
    else
        yad --title="Error" --text="Failed to pair with $SELECTED_DEVICE." --text-align=center \
            --button="OK" --center --width=500 --height=100
    fi
    
    sleep 5

    kill $YAD_PID

    bluetoothctl connect "$mac_addr"
    if bluetoothctl info "$mac_addr" | grep -q "Connected: yes"; then
        yad --title="Success" --text="Successfully connected to $SELECTED_DEVICE." --text-align=center \
            --center --width=500 --height=100 &
        YAD_PID=$!
    else
        yad --title="Error" --text="Failed to connect to $SELECTED_DEVICE." --text-align=center \
            --button="OK" --center --width=500 --height=100
    fi

    sleep 5

    kill $YAD_PID

    sleep 5
    bluetoothctl disconnect "$mac_addr"
    if bluetoothctl info "$mac_addr" | grep -q "Connected: no"; then
        yad --title="Success" --text="Successfully disconnected from $SELECTED_DEVICE." --text-align=center \
            --center --width=500 --height=100 &
        YAD_PID=$!
    else
        yad --title="Warning" --text="Device $SELECTED_DEVICE may still be connected." --text-align=center \
            --button="OK" --center --width=500 --height=100
    fi

    sleep 5

    kill $YAD_PID


    yad --title="Success" --text="Your HT is now ready to connect." --text-align=center --button="OK" --center
}

# Main GUI
pair_bluetooth