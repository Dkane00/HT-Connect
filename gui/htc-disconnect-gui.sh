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

# Function to disconnect Bluetooth
disconnect_bluetooth() {
    kissattach_pid=$(pgrep -f "kissattach /dev/rfcomm")
    if [ -n "$kissattach_pid" ]; then
        sudo kill "$kissattach_pid"
        sleep 2
        yad --title="Success" --text="Kissattach process stopped." --width=300 --height=100 --center &
        YAD_PID=$!
        sleep 5
        kill $YAD_PID
    else
        yad --title="Info" --text="No active kissattach connection found." --width=300 --height=100 --center &
        YAD_PID=$!
        sleep 5
        kill $YAD_PID
    fi

    socat_pid=$(pgrep -f "socat -d tcp-listen:9100")
    if [ -n "$socat_pid" ]; then
        sudo kill "$socat_pid"
        sleep 2
        yad --title="Success" --text="Socat process stopped." --width=300 --height=100 --center &
        YAD_PID=$!
        sleep 5
        kill $YAD_PID
    else
        yad --title="Info" --text="No active socat process found." --width=300 --height=100 --center &
        YAD_PID=$!
        sleep 5
        kill $YAD_PID
    fi

    connected_device=$(bluetoothctl info | grep "Device" | awk '{print $2}')
    if [ -n "$connected_device" ]; then
        rfcomm_device=$(rfcomm | grep "$connected_device" | awk '{print $1}')
        if [ -n "$rfcomm_device" ]; then
            sudo rfcomm release "$rfcomm_device"
            sleep 2
            yad --title="Success" --text="RFCOMM binding released." --width=300 --height=100 --center &
            YAD_PID=$!
            sleep 5
            kill $YAD_PID
        else
            yad --title="Info" --text="No active RFCOMM binding found for $connected_device." --width=300 --height=100 --center &
            YAD_PID=$!
            sleep 5
            kill $YAD_PID
        fi

        bluetoothctl disconnect "$connected_device"
        sleep 2

        if bluetoothctl info "$connected_device" | grep -q "Connected: yes"; then
            yad --title="Error" --text="The device is still connected." --width=300 --height=100 --center &
            YAD_PID=$!
            sleep 5
            kill $YAD_PID
        else
            yad --title="Success" --text="The Bluetooth device has been fully disconnected but remains paired." --width=300 --height=100 --center &
            YAD_PID=$!
            sleep 5
            kill $YAD_PID
        fi
    else
        yad --title="Info" --text="No connected Bluetooth device found." --width=300 --height=100 --center &
        YAD_PID=$!
        sleep 5
        kill $YAD_PID
    fi

    # Function to check Bluetooth status and prompt user
    check_bluetooth() {
        if rfkill list bluetooth | grep -q "Soft blocked: no"; then
            yad --center --width=350 --height=150 --title="Bluetooth Options" \
                --button="Leave Bluetooth On and Exit:0" --button="Turn Off Bluetooth and Exit:1" \
                --text="Bluetooth is currently ON.\nWhat would you like to do?"
        
            choice=$?
        
            if [ "$choice" -eq 1 ]; then
                rfkill block bluetooth
            fi

            exit 0  # Exit after user makes a choice
        fi
    }

    # Run Bluetooth check
    check_bluetooth

}

# Main GUI
disconnect_bluetooth