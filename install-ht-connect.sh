#!/bin/bash

#### This script will install HT-Connect and HT-Disconnect as command-line executables

# Define paths for both scripts
CONNECT_SCRIPT_PATH="$HOME/HT-Connect/HT-Connect.sh"
DISCONNECT_SCRIPT_PATH="$HOME/HT-Connect/HT-Disconnect.sh"

CONNECT_COMMAND_NAME="ht-connect"
DISCONNECT_COMMAND_NAME="ht-disconnect"

CONNECT_LINK_PATH="/usr/local/bin/$CONNECT_COMMAND_NAME"
DISCONNECT_LINK_PATH="/usr/local/bin/$DISCONNECT_COMMAND_NAME"

# Function to install a script
install_script() {
    local script_path=$1
    local command_name=$2
    local link_path=$3

    # Check if the script exists
    if [ ! -f "$script_path" ]; then
        echo "Error: Script not found at $script_path"
        exit 1
    fi

    # Create a symbolic link to the script
    sudo ln -sf "$script_path" "$link_path"

    # Ensure the script is executable
    chmod +x "$script_path"

    echo "Command '$command_name' has been added. You can now run it by typing '$command_name' in the terminal."
}

# Install both scripts
install_script "$CONNECT_SCRIPT_PATH" "$CONNECT_COMMAND_NAME" "$CONNECT_LINK_PATH"
install_script "$DISCONNECT_SCRIPT_PATH" "$DISCONNECT_COMMAND_NAME" "$DISCONNECT_LINK_PATH"

echo "Installation complete. You can now use 'ht-connect' and 'ht-disconnect'."

