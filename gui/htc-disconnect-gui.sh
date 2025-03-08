#!/bin/bash

# Function to disconnect Bluetooth
disconnect_bluetooth() {
    kissattach_pid=$(pgrep -f "kissattach /dev/rfcomm")
    if [ -n "$kissattach_pid" ]; then
        sudo kill "$kissattach_pid"
        sleep 2
        yad --title="Success" --text="Kissattach process stopped." --button="OK" --width=300 --height=100
    else
        yad --title="Info" --text="No active kissattach connection found." --button="OK" --width=300 --height=100
    fi

    socat_pid=$(pgrep -f "socat -d tcp-listen:9100")
    if [ -n "$socat_pid" ]; then
        sudo kill "$socat_pid"
        sleep 2
        yad --title="Success" --text="Socat process stopped." --button="OK" --width=300 --height=100
    else
        yad --title="Info" --text="No active socat process found." --button="OK" --width=300 --height=100
    fi

    connected_device=$(bluetoothctl info | grep "Device" | awk '{print $2}')
    if [ -n "$connected_device" ]; then
        rfcomm_device=$(rfcomm | grep "$connected_device" | awk '{print $1}')
        if [ -n "$rfcomm_device" ]; then
            sudo rfcomm release "$rfcomm_device"
            sleep 1
            yad --title="Success" --text="RFCOMM binding released." --button="OK" --width=300 --height=100
        else
            yad --title="Info" --text="No active RFCOMM binding found for $connected_device." --button="OK" --width=300 --height=100
        fi

        bluetoothctl disconnect "$connected_device"
        sleep 2

        if bluetoothctl info "$connected_device" | grep -q "Connected: yes"; then
            yad --title="Error" --text="The device is still connected." --button="OK" --width=300 --height=100
        else
            yad --title="Success" --text="The Bluetooth device has been fully disconnected but remains paired." --button="OK" --width=300 --height=100
        fi
    else
        yad --title="Info" --text="No connected Bluetooth device found." --button="OK" --width=300 --height=100
    fi

    choice=$(yad --title="Bluetooth" --form --text="Would you like to turn off Bluetooth?" \
        --field="1. Turn off Bluetooth:BTN" --field="2. Leave Bluetooth on:BTN" --button="OK" --width=300 --height=100)
    case $choice in
        1*) sudo rfkill block bluetooth ;;
        2*) ;;
    esac
}

# Main GUI
disconnect_bluetooth