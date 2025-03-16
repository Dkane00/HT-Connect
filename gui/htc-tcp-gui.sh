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

# Function to set up TCP connection
setup_tcp_connection() {
    
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
    sudo nohup rfcomm connect "$rfcomm_index" "$mac_addr" 1 > /dev/null 2>&1 & disown
    sleep 10

    kill $YAD_PID

    if ! rfcomm | grep -q "rfcomm$rfcomm_index"; then
        yad --title="Error" --text="Failed to connect RFCOMM device ($rfcomm_device)." --button="OK" --center
        return 1
    fi

    TCP_PORT=$(yad --title="TCP Port" --form --field="Enter TCP Port (default: 9100):N" "9100" --button="OK" --center | awk -F'|' '{print $1}')
    if [ -z "$TCP_PORT" ]; then
        TCP_PORT=9100
    fi

    yad --title="Connecting" --text="Connecting $rfcomm_device to TCP port $TCP_PORT using socat" --text-align=center --center --width=500 --height=100 &
    YAD_PID=$!

    sudo nohup socat -d tcp-listen:$TCP_PORT,reuseaddr,fork file:$rfcomm_device,b115200,raw > /dev/null 2>&1 & disown
    sleep 2

    kill $YAD_PID

    if pgrep -f "socat -d tcp-listen:$TCP_PORT" > /dev/null; then
        yad --title="Success" --text="RFCOMM device $rfcomm_device is now available on TCP port $TCP_PORT." --button="OK" --center
    else
        yad --title="Error" --text="Socat failed to start." --button="OK" --center
    fi
}

# Main GUI
setup_tcp_connection