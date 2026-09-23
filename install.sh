#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

SCRIPT_NAME="login-tui"
SOURCE_FILE="login-tui.sh"
INSTALL_DIR="/usr/local/bin"

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run this script as root (using sudo)."
    exit 1
fi

# Check if the source file exists
if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: $SOURCE_FILE not found in the current directory."
    exit 1
fi

echo "Installing $SCRIPT_NAME..."

# Copy the file to the system binaries directory
cp "$SOURCE_FILE" "$INSTALL_DIR/$SCRIPT_NAME"

# Make the script executable
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

echo "Installation complete! You can now run the tool by typing '$SCRIPT_NAME' in your terminal."
