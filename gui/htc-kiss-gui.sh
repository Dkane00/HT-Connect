#!/bin/bash

# Request sudo once and cache credentials
ensure_sudo() {
    if ! sudo -v; then
        yad --title="Permission Error" --text="Failed to get sudo permissions." --button="OK" --center
        exit 1
    fi
}

# Ensure sudo access first
ensure_sudo

# Function to check Bluetooth status and prompt user
check_bluetooth() {
    if ! rfkill list bluetooth | grep -q "Soft blocked: no"; then
        yad --center --width=300 --height=150 --title="Bluetooth Off" --button="Turn On:0" --button="Exit:1" --text="Bluetooth is off.\nWould you like to turn it on?"
        choice=$?
        
        if [ "$choice" -eq 0 ]; then
            sudo rfkill unblock bluetooth
            sleep 5
        else
            yad --center --width=300 --height=100 --title="Exiting" --text="Bluetooth must be on to continue." --button="OK:0"
            exit 1
        fi
    fi
}

# Run Bluetooth check
check_bluetooth

# Function to set up KISS connection
setup_kiss_connection() {

    paired_devices=$(bluetoothctl paired-devices | grep -E 'UV-PRO|VR-N76')
    if [ -z "$paired_devices" ]; then
        yad --title="Error" --text="No paired devices found with names 'UV-PRO' or 'VR-N76'." --button="OK" --center
        return 1
    fi

    mac_addr=$(echo "$paired_devices" | awk '{print $2}' | head -n 1)
    rfcomm_index=0
    rfcomm_device="/dev/rfcomm$rfcomm_index"

    yad --title="Connecting" --text="Connecting $mac_addr to rfcomm serial port" --text-align=center --center --width=500 --height=100 &
    YAD_PID=$!
    
    sudo rfcomm release "$rfcomm_index" 2>/dev/null
    sudo nohup rfcomm connect "$rfcomm_index" "$mac_addr" &> nohup_rfcomm.log & disown

    sleep 10

    kill $YAD_PID

    if ! rfcomm | grep -q "rfcomm$rfcomm_index"; then
        yad --title="Error" --text="Failed to connect RFCOMM device ($rfcomm_device)." --button="OK" --center
        return 1
    fi

    INTERFACE_NAME=$(yad --title="Interface Name" --form --field="Enter interface name (default: wl2k):" "wl2k" --button="OK" --center | awk -F'|' '{print $1}')
    if [ -z "$INTERFACE_NAME" ]; then
        INTERFACE_NAME="wl2k"
    fi

    yad --title="Connecting" --text="Connecting "$rfcomm_device" to "$INTERFACE_NAME" with kissattach" --text-align=center --center --width=500 --height=100 &
    YAD_PID=$!

    # Run kissattach with the provided interface name
    sudo kissattach "$rfcomm_device" "$INTERFACE_NAME"
    
    sleep 5

    kill $YAD_PID

    # Check if the ax0 interface was created
    if ! ip link show ax0 &>/dev/null; then
        yad --title="Error" --text="Failed to create KISS interface 'ax0'." --button="OK" --center
        return 1
    fi

    yad --title="Success" --text="RFCOMM device is now connected to KISS interface 'ax0'." --button="OK" --center
}

# Main GUI
setup_kiss_connection