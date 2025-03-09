#!/bin/bash

# Define script paths
INSTALL_DIR="$HOME/HT-Connect"
CONNECT_SCRIPT_PATH="$INSTALL_DIR/connect.sh"
DISCONNECT_SCRIPT_PATH="$INSTALL_DIR/disconnect.sh"
PAIRING_SCRIPT_PATH="$INSTALL_DIR/pairing.sh"
TCP_CONNECT_SCRIPT_PATH="$INSTALL_DIR/tcp-connect.sh"
KISS_CONNECT_SCRIPT_PATH="$INSTALL_DIR/kiss-connect.sh"
GUI_SCRIPT_PATH="$INSTALL_DIR/htc-connect-gui.sh"
ICON_PATH="$INSTALL_DIR/ht.png"

# Define command names
HTC_COMMAND="htc"
HTC_COMMAND_PATH="/usr/local/bin/$HTC_COMMAND"

# Define individual command names
CONNECT_COMMAND_NAME="htc-connect"
DISCONNECT_COMMAND_NAME="htc-disconnect"
PAIRING_COMMAND_NAME="htc-pair"
TCP_COMMAND_NAME="htc-tcp"
KISS_COMMAND_NAME="htc-kiss"

CONNECT_LINK_PATH="/usr/local/bin/$CONNECT_COMMAND_NAME"
DISCONNECT_LINK_PATH="/usr/local/bin/$DISCONNECT_COMMAND_NAME"
PAIRING_LINK_PATH="/usr/local/bin/$PAIRING_COMMAND_NAME"
TCP_LINK_PATH="/usr/local/bin/$TCP_COMMAND_NAME"
KISS_LINK_PATH="/usr/local/bin/$KISS_COMMAND_NAME"

# Function to check if a package is installed and install if missing
check_and_install() {
    local package_name=$1
    if ! dpkg -s "$package_name" &>/dev/null; then
        echo "$package_name is not installed. Installing..."
        sudo apt-get install -y "$package_name"
    else
        echo "$package_name is already installed."
    fi
}

# Check and install required dependencies
check_and_install "socat"
check_and_install "ax25-tools"
check_and_install "yad"

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

    if [ ! -f "$script_path" ]; then
        echo "Error: Script not found at $script_path"
        exit 1
    fi

    remove_existing_command "$command_name" "$link_path"
    sudo ln -sf "$script_path" "$link_path"
    chmod +x "$script_path"
    echo "Command '$command_name' has been added. You can now run it by typing '$command_name' in the terminal."
}

# Install scripts
install_script "$CONNECT_SCRIPT_PATH" "$CONNECT_COMMAND_NAME" "$CONNECT_LINK_PATH"
install_script "$DISCONNECT_SCRIPT_PATH" "$DISCONNECT_COMMAND_NAME" "$DISCONNECT_LINK_PATH"
install_script "$PAIRING_SCRIPT_PATH" "$PAIRING_COMMAND_NAME" "$PAIRING_LINK_PATH"
install_script "$TCP_CONNECT_SCRIPT_PATH" "$TCP_COMMAND_NAME" "$TCP_LINK_PATH"
install_script "$KISS_CONNECT_SCRIPT_PATH" "$KISS_COMMAND_NAME" "$KISS_LINK_PATH"

# Configure axports for kissattach
AXPORTS_FILE="/etc/ax25/axports"
echo "Checking axports configuration..."
if ! grep -q "^wl2k" "$AXPORTS_FILE"; then
    read -p "Enter your Amateur Radio call-sign: " CALLSIGN
    echo "wl2k $CALLSIGN 1200 255 7 Winlink" | sudo tee -a "$AXPORTS_FILE" > /dev/null
    echo "Added wl2k entry to $AXPORTS_FILE."
else
    echo "wl2k entry already exists in $AXPORTS_FILE. No changes made."
fi

# Create the 'htc' command script
cat <<EOL | sudo tee "$HTC_COMMAND_PATH" > /dev/null
#!/bin/bash

case "\$1" in
    pair)
        $PAIRING_COMMAND_NAME
        ;;
    connect)
        $CONNECT_COMMAND_NAME
        ;;
    disconnect)
        $DISCONNECT_COMMAND_NAME
        ;;
    tcp)
        $TCP_COMMAND_NAME
        ;;
    kiss)
        $KISS_COMMAND_NAME
        ;;
    --help|-h)
        echo -e "\nAvailable 'htc' commands:\n"
        echo -e "  1. htc pair       - Scan, pair, and trust a new Bluetooth device"
        echo -e "  2. htc connect    - Connect to a previously paired device and bind to RFCOMM"
        echo -e "  3. htc disconnect - Disconnect the Bluetooth device and release RFCOMM"
        echo -e "  4. htc tcp        - Connect the ht tnc to a TCP port using socat"
        echo -e "  5. htc kiss       - Connect the ht tnc to kissattach"
        echo -e "\nUsage: htc <command>\n"
        ;;
    *)
        echo "Invalid command. Use 'htc --help' for a list of available commands."
        exit 1
        ;;
esac
EOL

# Ensure the 'htc' script is executable
sudo chmod +x "$HTC_COMMAND_PATH"

# Create a desktop entry for the GUI script
MENU_ENTRY_PATH="$HOME/.local/share/applications/htc-connect.desktop"
echo "Creating menu entry for HTC Connect GUI..."
mkdir -p "$HOME/.local/share/applications"
cat <<EOF > "$MENU_ENTRY_PATH"
[Desktop Entry]
Name=HTC Connect
Exec=$GUI_SCRIPT_PATH
Icon=$ICON_PATH
Type=Application
Categories=Utility;Network;
Terminal=false
EOF
chmod +x "$MENU_ENTRY_PATH"
echo "Menu entry created at $MENU_ENTRY_PATH."

echo "Installation complete! You can now use:"
echo "  - htc pair       (Pair a Bluetooth device)"
echo "  - htc connect    (Connect an already paired device)"
echo "  - htc disconnect (Disconnect and release the device)"
echo "  - htc tcp        (connect ht tnc to tcp port)"
echo "  - htc kiss       (connect ht tnc to kissattach)"
echo "  - htc --help     (View available commands)"
