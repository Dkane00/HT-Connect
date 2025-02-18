#!/bin/bash

#### This script will take the HT-Connect script and make it executable from the command line
#### using the commad: ht-connect

# Define the path to the script
SCRIPT_PATH="$HOME/HT-Connect/Bluetooth_Menu.sh"
COMMAND_NAME="ht-connect"
LINK_PATH="/usr/local/bin/$COMMAND_NAME"

# Check if the script exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Error: Script not found at $SCRIPT_PATH"
    exit 1
fi

# Create a symbolic link to the script
sudo ln -sf "$SCRIPT_PATH" "$LINK_PATH"

# Ensure the script is executable
chmod +x "$SCRIPT_PATH"

echo "Command '$COMMAND_NAME' has been added. You can now run it by typing '$COMMAND_NAME' in the terminal."
