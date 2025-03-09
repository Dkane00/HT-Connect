#!/bin/bash

# Function to disconnect Bluetooth
disconnect_bluetooth() {
    kissattach_pid=$(pgrep -f "kissattach /dev/rfcomm")
    if [ -n "$kissattach_pid" ]; then
        sudo kill "$kissattach_pid"
        sleep 2
        yad --title="Success" --text="Kissattach process stopped." --button="OK" --width=300 --height=100 --center
    else
        yad --title="Info" --text="No active kissattach connection found." --button="OK" --width=300 --height=100 --center
    fi

    socat_pid=$(pgrep -f "socat -d tcp-listen:9100")
    if [ -n "$socat_pid" ]; then
        sudo kill "$socat_pid"
        sleep 2
        yad --title="Success" --text="Socat process stopped." --button="OK" --width=300 --height=100 --center
    else
        yad --title="Info" --text="No active socat process found." --button="OK" --width=300 --height=100 --center
    fi

    connected_device=$(bluetoothctl info | grep "Device" | awk '{print $2}')
    if [ -n "$connected_device" ]; then
        rfcomm_device=$(rfcomm | grep "$connected_device" | awk '{print $1}')
        if [ -n "$rfcomm_device" ]; then
            sudo rfcomm release "$rfcomm_device"
            sleep 1
            yad --title="Success" --text="RFCOMM binding released." --button="OK" --width=300 --height=100 --center
        else
            yad --title="Info" --text="No active RFCOMM binding found for $connected_device." --button="OK" --width=300 --height=100 --center
        fi

        bluetoothctl disconnect "$connected_device"
        sleep 2

        if bluetoothctl info "$connected_device" | grep -q "Connected: yes"; then
            yad --title="Error" --text="The device is still connected." --button="OK" --width=300 --height=100 --center
        else
            yad --title="Success" --text="The Bluetooth device has been fully disconnected but remains paired." --button="OK" --width=300 --height=100 --center
        fi
    else
        yad --title="Info" --text="No connected Bluetooth device found." --button="OK" --width=300 --height=100 --center
    fi

    # Function to check Bluetooth status and prompt user
    check_bluetooth() {
        if rfkill list bluetooth | grep -q "Soft blocked: no"; then
            yad --center --width=350 --height=150 --title="Bluetooth Options" \
                --button="Leave On & Exit:0" --button="Turn Off & Exit:1" \
                --text="Bluetooth is currently ON.\nWhat would you like to do?"
        
            choice=$?
        
            if [ "$choice" -eq 1 ]; then
                rfkill block bluetooth
            fi

            exit 0  # Exit after user makes a choice
        fi
    }

}

# Main GUI
disconnect_bluetooth