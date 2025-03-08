#!/bin/bash

# Function to run a script with sudo password prompt
run_script() {
    local script=$1
    local title=$2
    # Prompt for sudo password and run the script
    password=$(yad --title="$title" --form --field="Enter sudo password:H" --button="OK" | awk -F'|' '{print $1}')
    echo "$password" | sudo -S bash -c "$script"
}

# Function to check if Bluetooth is turned off and prompt to turn it on
check_bluetooth() {
    if rfkill list bluetooth | grep -q "Soft blocked: yes"; then
        yad --title="Bluetooth Off" --form --text="Bluetooth is currently turned off." \
            --field="Turn on Bluetooth:BTN" "bash -c 'sudo rfkill unblock bluetooth'" \
            --button="Exit" --width=300 --height=100
        return 1
    fi
    return 0
}

# Function to search for paired devices
search_paired_devices() {
    paired_devices=$(bluetoothctl paired-devices | grep -E 'UV-PRO|VN76')
    if [ -z "$paired_devices" ]; then
        yad --title="Error" --text="No paired devices found with names 'UV-PRO' or 'VN76'." --button="OK" --width=300 --height=100
        return 1
    fi
    echo "$paired_devices"
}

# Function to connect to a Bluetooth device
connect_bluetooth() {
    if ! check_bluetooth; then
        return
    fi

    paired_devices=$(search_paired_devices)
    if [ -z "$paired_devices" ]; then
        return
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

# Function to pair a Bluetooth device
pair_bluetooth() {
    if ! check_bluetooth; then
        return
    fi

    yad --title="Pairing" --text="Make sure that your HT is in pairing mode if you have never paired the HT with this device." \
        --field="1. My HT is Ready, Proceed:BTN" --field="2. Exit:BTN" --button="OK" --width=300 --height=100
    case $choice in
        1*) ;;
        2*) return ;;
    esac

    bluetoothctl scan on &
    scan_pid=$!
    sleep 10
    bluetoothctl scan off || sudo pkill -f "bluetoothctl scan on"

    scan_results=$(bluetoothctl devices)
    if [ -z "$scan_results" ]; then
        yad --title="Error" --text="No Bluetooth devices found." --button="OK" --width=300 --height=100
        return
    fi

    declare -A device_map
    index=1
    while read -r line; do
        mac=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | cut -d ' ' -f3-)
        device_map[$index]="$mac $name"
        printf "${GREEN}%d. %s (%s)${NC}\n" "$index" "$name" "$mac"
        ((index++))
    done <<< "$scan_results"

    choice=$(yad --title="Select Device" --form --text="Select the device you want to pair:" \
        --field="Device:CB" "$(for key in "${!device_map[@]}"; do echo "$key. ${device_map[$key]}"; done)" --button="OK" --width=300 --height=100)
    mac_addr=$(echo "${device_map[$choice]}" | awk '{print $1}')

    bluetoothctl pair "$mac_addr"
    bluetoothctl trust "$mac_addr"

    if bluetoothctl info "$mac_addr" | grep -q "Paired: yes"; then
        yad --title="Success" --text="Successfully paired with ${device_map[$choice]}." --button="OK" --width=300 --height=100
    else
        yad --title="Error" --text="Failed to pair with ${device_map[$choice]}." --button="OK" --width=300 --height=100
    fi

    bluetoothctl connect "$mac_addr"
    if bluetoothctl info "$mac_addr" | grep -q "Connected: yes"; then
        yad --title="Success" --text="Successfully connected to ${device_map[$choice]}." --button="OK" --width=300 --height=100
    else
        yad --title="Error" --text="Failed to connect to ${device_map[$choice]}." --button="OK" --width=300 --height=100
    fi

    sleep 5
    bluetoothctl disconnect "$mac_addr"
    if bluetoothctl info "$mac_addr" | grep -q "Connected: no"; then
        yad --title="Success" --text="Successfully disconnected from ${device_map[$choice]}." --button="OK" --width=300 --height=100
    else
        yad --title="Warning" --text="Device ${device_map[$choice]} may still be connected." --button="OK" --width=300 --height=100
    fi

    yad --title="Success" --text="Your HT is now ready to connect." --button="OK" --width=300 --height=100
}

# Function to set up KISS connection
kiss_connect() {
    if ! check_bluetooth; then
        return
    fi

    paired_devices=$(search_paired_devices)
    if [ -z "$paired_devices" ]; then
        return
    fi

    mac_addr=$(echo "$paired_devices" | awk '{print $2}' | head -n 1)
    rfcomm_index=0
    rfcomm_device="/dev/rfcomm$rfcomm_index"

    sudo rfcomm release "$rfcomm_index" 2>/dev/null
    sudo nohup rfcomm connect "$rfcomm_index" "$mac_addr" &> nohup_rfcomm.log & disown
    sleep 10

    if ! rfcomm | grep -q "rfcomm$rfcomm_index"; then
        yad --title="Error" --text="Failed to connect RFCOMM device ($rfcomm_device)." --button="OK" --width=300 --height=100
        return
    fi

    sudo kissattach "$rfcomm_device" wl2k
    if ! ip link show ax0 &>/dev/null; then
        yad --title="Error" --text="Failed to create KISS interface 'wl2k'." --button="OK" --width=300 --height=100
        return
    fi

    yad --title="Success" --text="RFCOMM device is now connected to KISS interface 'wl2k'." --button="OK" --width=300 --height=100
}

# Function to set up TCP connection
tcp_connect() {
    if ! check_bluetooth; then
        return
    fi

    paired_devices=$(search_paired_devices)
    if [ -z "$paired_devices" ]; then
        return
    fi

    mac_addr=$(echo "$paired_devices" | awk '{print $2}' | head -n 1)
    rfcomm_index=0
    rfcomm_device="/dev/rfcomm$rfcomm_index"

    sudo rfcomm release "$rfcomm_index" 2>/dev/null
    sudo nohup rfcomm connect "$rfcomm_index" "$mac_addr" 1 > /dev/null 2>&1 & disown
    sleep 10

    if ! rfcomm | grep -q "rfcomm$rfcomm_index"; then
        yad --title="Error" --text="Failed to connect RFCOMM device ($rfcomm_device)." --button="OK" --width=300 --height=100
        return
    fi

    TCP_PORT=9100
    sudo nohup socat -d tcp-listen:$TCP_PORT,reuseaddr,fork file:$rfcomm_device,b115200,raw > /dev/null 2>&1 & disown
    sleep 2

    if pgrep -f "socat -d tcp-listen:$TCP_PORT" > /dev/null; then
        yad --title="Success" --text="RFCOMM device $rfcomm_device is now available on TCP port $TCP_PORT." --button="OK" --width=300 --height=100
    else
        yad --title="Error" --text="Socat failed to start." --button="OK" --width=300 --height=100
    fi
}

# Main GUI
yad --title="HT Connect" --form \
    --field="Connect Bluetooth:BTN" "bash -c 'source $0; connect_bluetooth'" \
    --field="Disconnect Bluetooth:BTN" "bash -c 'source $0; disconnect_bluetooth'" \
    --field="KISS Connect:BTN" "bash -c 'source $0; kiss_connect'" \
    --field="Pairing:BTN" "bash -c 'source $0; pair_bluetooth'" \
    --field="TCP Connect:BTN" "bash -c 'source $0; tcp_connect'" \
    --button="Exit" --width=400 --height=300