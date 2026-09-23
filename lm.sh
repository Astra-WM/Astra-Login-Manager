#!/bin/bash

# Clear screen and hide cursor
clear
tput civis

# Function to restore cursor on exit
cleanup() {
    tput cnorm
    clear
}
trap cleanup EXIT

# Colors and UI formatting (ANSI Escape Codes)
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Get terminal dimensions
TERM_LINES=$(tput lines)
TERM_COLS=$(tput cols)

# Panel boundaries (Centered Box)
BOX_WIDTH=46
BOX_HEIGHT=12
START_ROW=$(( (TERM_LINES - BOX_HEIGHT) / 2 ))
START_COL=$(( (TERM_COLS - BOX_WIDTH) / 2 ))

# Draw Box Borders
draw_box() {
    # Top border
    tput cup $START_ROW $START_COL
    printf "${CYAN}┌──────────────────────────────────────────────┐${NC}"
    
    # Side borders
    for ((i=1; i<BOX_HEIGHT-1; i++)); do
        tput cup $((START_ROW + i)) $START_COL
        printf "${CYAN}│                                              │${NC}"
    done
    
    # Bottom border
    tput cup $((START_ROW + BOX_HEIGHT - 1)) $START_COL
    printf "${CYAN}└──────────────────────────────────────────────┘${NC}"
}

# Main UI Render Setup
draw_box
tput cup $((START_ROW + 2)) $((START_COL + 16))
printf "${WHITE}SECURE TUI LOGIN${NC}"

tput cup $((START_ROW + 5)) $((START_COL + 6))
printf "${GRAY}Username:${NC} ___________________________"

tput cup $((START_ROW + 7)) $((START_COL + 6))
printf "${GRAY}Password:${NC} ___________________________"

# --- 1. Get Username ---
tput cnorm # Show cursor for input
tput cup $((START_ROW + 5)) $((START_COL + 16))
read -r username

# --- 2. Get Masked Password ---
tput cup $((START_ROW + 7)) $((START_COL + 16))

password=""
while IFS= read -r -s -n1 char; do
    # Handle Enter key
    if [[ -z $char ]]; then
        break
    fi
    # Handle Backspace
    if [[ $char == $'\x7f' ]]; then
        if [ ${#password} -gt 0 ]; then
            password="${password%?}"
            # Move back, erase character, move back again
            printf "\b \b"
        fi
    else
        password+="$char"
        printf "*"
    fi
done

tput civis # Hide cursor again

# --- 3. Process Authentication Logic ---
tput cup $((START_ROW + 10)) $((START_COL + 4))

# Dummy credentials check (Replace this with real logic)
if [[ "$username" == "admin" && "$password" == "secret" ]]; then
    printf "${GREEN}✔ Access Granted. Welcome, %s!${NC}" "$username"
    sleep 2
    exit 0
else
    printf "${RED}✘ Authentication Failed. Invalid credentials.${NC}"
    sleep 2
    exit 1
fi
