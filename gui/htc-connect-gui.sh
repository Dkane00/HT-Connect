#!/bin/bash

# Function to connect to a Bluetooth device
connect_bluetooth() {
    paired_devices=$(bluetoothctl paired-devices | grep -E 'UV-PRO|VN76')
    if [ -z "$paired_devices" ]; then
        yad --title="Error" --text="No paired devices found with names 'UV-PRO' or 'VN76'." --button="OK" --width=300 --height=100
        return 1
    fi

    mac_addr=$(echo "$paired_devices" | awk '{print $2}' | head -n 1)
    rfcomm_index=0
    rfcomm_device="/dev/rfcomm$rfcomm_index"

    sudo rfcomm release "$rfcomm_index" 2>/dev/null
    sudo nohup rfcomm connect "$rfcomm_index" "$mac_addr" &> nohup_rfcomm.log & disown
    sleep 10

    if rfcomm | grep -q "rfcomm$rfcomm_index"; then
        yad --title="Success" --text="Device $mac_addr is now connected to $rfcomm_device." --button="OK" --width=300 --height=100
    else
        yad --title="Error" --text="Failed to connect RFCOMM device ($rfcomm_device)." --button="OK" --width=300 --height=100
    fi
}

# Main GUI
connect_bluetooth