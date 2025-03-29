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
    
    paired_devices=$(bluetoothctl paired-devices | grep -E 'UV-PRO|VR-N76|GA-5WB|TH-D74|TH-D75|VR-N7500')
    if [ -z "$paired_devices" ]; then
        yad --title="Error" --text="No paired devices found with names 'UV-PRO', 'VR-N76', 'TH-D74', 'TH-D75', 'GA-5WB', or 'VR-N7500'." \
            --button="OK" --width=300 --height=100 --center
        return 1
    fi

    # Convert devices list to format for yad dropdown (Device Name first, then MAC Address)
    DEVICES_LIST=""
    while read -r line; do
        mac=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | cut -d ' ' -f3-)
        DEVICES_LIST+="$name ($mac)!"
    done <<< "$paired_devices"

    # Remove trailing "!" from the list
    DEVICES_LIST="${DEVICES_LIST%!}"

    # Show devices in a drop-down menu
    SELECTED_DEVICE=$(yad --center --width=500 --height=100 --title="Select Bluetooth Device" --form \
        --field="Devices:CB" "$DEVICES_LIST" --button="Connect:0" --button="Cancel:1")
    
    # Extract the selected MAC address
    mac_addr=$(echo "$SELECTED_DEVICE" | awk -F '[()]' '{print $2}')

    
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