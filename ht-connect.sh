#!/bin/bash

# Main GUI
yad --title="HT Connect" --form \
    --field="Connect Bluetooth:BTN" "bash -c './gui/htc-connect-gui.sh'" \
    --field="Disconnect Bluetooth:BTN" "bash -c './gui/htc-disconnect-gui.sh'" \
    --field="KISS Connect:BTN" "bash -c './gui/htc-kiss-gui.sh'" \
    --field="Pairing:BTN" "bash -c './gui/htc-pair-gui.sh'" \
    --field="TCP Connect:BTN" "bash -c './gui/htc-tcp-gui.sh'" \
    --button="Exit" --width=400 --height=300