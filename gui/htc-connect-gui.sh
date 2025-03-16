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

# Function to connect to a Bluetooth device
connect_bluetooth() {
    paired_devices=$(bluetoothctl paired-devices | grep -E 'UV-PRO|VN76')
    if [ -z "$paired_devices" ]; then
        yad --title="Error" --text="No paired devices found with names 'UV-PRO' or 'VN76'." --button="OK" --width=300 --height=100 --center
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

    if rfcomm | grep -q "rfcomm$rfcomm_index"; then
        yad --title="Success" --text="Device $mac_addr is now connected to $rfcomm_device." --button="OK" --width=300 --height=100 --center
    else
        yad --title="Error" --text="Failed to connect RFCOMM device ($rfcomm_device)." --button="OK" --width=300 --height=100 --center
    fi
}

# Main GUI
connect_bluetooth