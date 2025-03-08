#!/bin/bash

# Function to set up TCP connection
setup_tcp_connection() {
    if ! rfkill list bluetooth | grep -q "Soft blocked: no"; then
        yad --title="Bluetooth Off" --text="Bluetooth is currently turned off. Please turn it on first." --button="OK" --width=300 --height=100
        return 1
    fi

    paired_devices=$(bluetoothctl paired-devices | grep -E 'UV-PRO|VN76')
    if [ -z "$paired_devices" ]; then
        yad --title="Error" --text="No paired devices found with names 'UV-PRO' or 'VN76'." --button="OK" --width=300 --height=100
        return 1
    fi

    mac_addr=$(echo "$paired_devices" | awk '{print $2}' | head -n 1)
    rfcomm_index=0
    rfcomm_device="/dev/rfcomm$rfcomm_index"

    sudo rfcomm release "$rfcomm_index" 2>/dev/null
    sudo nohup rfcomm connect "$rfcomm_index" "$mac_addr" 1 > /dev/null 2>&1 & disown
    sleep 10

    if ! rfcomm | grep -q "rfcomm$rfcomm_index"; then
        yad --title="Error" --text="Failed to connect RFCOMM device ($rfcomm_device)." --button="OK" --width=300 --height=100
        return 1
    fi

    TCP_PORT=$(yad --title="TCP Port" --form --field="Enter TCP Port (default: 9100):N" "9100" --button="OK" --width=300 --height=100 | awk -F'|' '{print $1}')
    if [ -z "$TCP_PORT" ]; then
        TCP_PORT=9100
    fi

    sudo nohup socat -d tcp-listen:$TCP_PORT,reuseaddr,fork file:$rfcomm_device,b115200,raw > /dev/null 2>&1 & disown
    sleep 2

    if pgrep -f "socat -d tcp-listen:$TCP_PORT" > /dev/null; then
        yad --title="Success" --text="RFCOMM device $rfcomm_device is now available on TCP port $TCP_PORT." --button="OK" --width=300 --height=100
    else
        yad --title="Error" --text="Socat failed to start." --button="OK" --width=300 --height=100
    fi
}

# Main GUI
setup_tcp_connection