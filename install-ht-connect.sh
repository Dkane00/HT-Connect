#!/bin/bash

# Define script paths
INSTALL_DIR="$HOME/HT-Connect"
CONNECT_SCRIPT_PATH="$INSTALL_DIR/connect.sh"
DISCONNECT_SCRIPT_PATH="$INSTALL_DIR/disconnect.sh"
PAIRING_SCRIPT_PATH="$INSTALL_DIR/pairing.sh"
HT_SCRIPT_PATH="$INSTALL_DIR/ht.sh"

# Define command names
HT_COMMAND="ht"
HT_COMMAND_PATH="/usr/local/bin/$HT_COMMAND"

# Define individual command names
CONNECT_COMMAND_NAME="ht-connect"
DISCONNECT_COMMAND_NAME="ht-disconnect"
PAIRING_COMMAND_NAME="ht-pair"

CONNECT_LINK_PATH="/usr/local/bin/$CONNECT_COMMAND_NAME"
DISCONNECT_LINK_PATH="/usr/local/bin/$DISCONNECT_COMMAND_NAME"
PAIRING_LINK_PATH="/usr/local/bin/$PAIRING_COMMAND_NAME"

# Function to remove an existing command
remove_existing_command() {
    local command_name=$1
    local link_path=$2
    if [ -L "$link_path" ]; then
        echo "Removing existing command $command_name..."
        sudo rm -f "$link_path"
    fi
}

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

    # Remove existing command if necessary
    remove_existing_command "$command_name" "$link_path"

    # Create a symbolic link to the script
    sudo ln -sf "$script_path" "$link_path"

    # Ensure the script is executable
    chmod +x "$script_path"

    echo "Command '$command_name' has been added. You can now run it by typing '$command_name' in the terminal."
}

# Install scripts
install_script "$CONNECT_SCRIPT_PATH" "$CONNECT_COMMAND_NAME" "$CONNECT_LINK_PATH"
install_script "$DISCONNECT_SCRIPT_PATH" "$DISCONNECT_COMMAND_NAME" "$DISCONNECT_LINK_PATH"
install_script "$PAIRING_SCRIPT_PATH" "$PAIRING_COMMAND_NAME" "$PAIRING_LINK_PATH"

# Install the main 'ht' script
if [ -f "$HT_SCRIPT_PATH" ]; then
    remove_existing_command "$HT_COMMAND_PATH"
    sudo ln -sf "$HT_SCRIPT_PATH" "$HT_COMMAND_PATH"
    sudo chmod +x "$HT_SCRIPT_PATH"
    echo "Installed: ht (main command)"
else
    echo "Error: 'ht.sh' script not found at $HT_SCRIPT_PATH"
    exit 1
fi

echo "Installation complete! You can now use:"
echo "  - ht pair       (Pair a Bluetooth device)"
echo "  - ht connect    (Connect an already paired device)"
echo "  - ht disconnect (Disconnect and release the device)"
echo "  - ht            (View available commands)"
