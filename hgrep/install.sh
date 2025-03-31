#!/usr/bin/env bash

# hgrep installer script
# This script will install hgrep by adding the function to your shell configuration

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo -e "${BLUE}Starting hgrep installation...${NC}"

# Determine which shell configuration file to use
SHELL_NAME=$(basename "$SHELL")
if [ "$SHELL_NAME" = "zsh" ]; then
    CONFIG_FILE="$HOME/.zshrc"
elif [ "$SHELL_NAME" = "bash" ]; then
    CONFIG_FILE="$HOME/.bashrc"
    # For macOS, check if we need to use .bash_profile instead
    if [[ "$OSTYPE" == "darwin"* ]] && [ -f "$HOME/.bash_profile" ]; then
        CONFIG_FILE="$HOME/.bash_profile"
    fi
else
    CONFIG_FILE="$HOME/.profile"
fi

# Check if hgrep function is already defined in the config file
if grep -q "function hgrep" "$CONFIG_FILE" || grep -q "hgrep()" "$CONFIG_FILE"; then
    echo -e "${YELLOW}hgrep function already exists in $CONFIG_FILE.${NC}"
    read -p "Do you want to replace it? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Installation cancelled.${NC}"
        exit 1
    fi
    # Remove existing function
    TEMP_FILE=$(mktemp)
    sed '/# hgrep function definition/,/^}$/d' "$CONFIG_FILE" > "$TEMP_FILE"
    cp "$TEMP_FILE" "$CONFIG_FILE"
    rm "$TEMP_FILE"
    echo -e "${YELLOW}Removed existing hgrep function.${NC}"
fi

# Read the hgrep function definition
HGREP_SOURCE="$SCRIPT_DIR/hgrep-function.sh"

if [ ! -f "$HGREP_SOURCE" ]; then
    echo -e "${RED}Error: Could not find hgrep-function.sh in $SCRIPT_DIR${NC}"
    exit 1
fi

# Add function definition to the config file
echo -e "\n# Added by hgrep installer" >> "$CONFIG_FILE"
echo -e "# hgrep function to search command history, count occurrences, and copy most frequent command" >> "$CONFIG_FILE"
cat "$HGREP_SOURCE" >> "$CONFIG_FILE"

echo -e "${GREEN}hgrep function has been added to $CONFIG_FILE${NC}"

# Check if clipboard utilities are available
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS should have pbcopy pre-installed
    if ! command -v pbcopy >/dev/null 2>&1; then
        echo -e "${YELLOW}Warning: pbcopy not found. Clipboard functionality may not work.${NC}"
    fi
else
    # Linux systems
    if ! command -v xclip >/dev/null 2>&1 && ! command -v wl-copy >/dev/null 2>&1; then
        echo -e "${YELLOW}Warning: No clipboard utility found. For clipboard support install xclip:${NC}"
        echo -e "${YELLOW}  sudo apt-get install xclip    # For Debian/Ubuntu${NC}"
        echo -e "${YELLOW}  sudo yum install xclip        # For CentOS/RHEL${NC}"
        echo -e "${YELLOW}  sudo dnf install xclip        # For Fedora${NC}"
        echo -e "${YELLOW}Or for Wayland:${NC}"
        echo -e "${YELLOW}  sudo apt-get install wl-clipboard    # For Debian/Ubuntu${NC}"
    fi
fi

echo -e "${GREEN}Installation complete!${NC}"
echo -e "${BLUE}To start using hgrep, restart your terminal or run:${NC}"
echo -e "${YELLOW}source $CONFIG_FILE${NC}"
echo -e "${BLUE}Then try: ${YELLOW}hgrep git${NC}"