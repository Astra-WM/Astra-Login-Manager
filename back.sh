#!/usr/bin/env bash

# Strictly enforce error handling and secure paths
set -euo pipefail
IFS=$'\n\t'
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Configuration
LOG_FILE="/var/log/bash-login-manager.log"

log_message() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$LOG_FILE"
}

authenticate_user() {
    local username="$1"
    local password="$2"

    # Method 1: Authenticate via PAM if pamtester is installed (Recommended & Secure)
    if command -v pamtester &> /dev/null; then
        if echo "$password" | pamtester login "$username" authenticate &> /dev/null; then
            return 0
        fi
    # Method 2: Fallback to manual shadow verification (Requires root execution)
    elif [[ -f /etc/shadow ]]; then
        local shadow_line
        shadow_line=$(getent shadow "$username" || true)
        if [[ -z "$shadow_line" ]]; then
            return 1
        fi
        
        local salt_hash
        salt_hash=$(echo "$shadow_line" | cut -d: -f2)
        
        # Extract the salt structure (e.g., $6$saltsalt$)
        local salt
        salt=$(echo "$salt_hash" | grep -oP '^\$[^\$]+\$[^\$]+\$')
        
        local encrypted
        encrypted=$(openssl passwd -in <(echo -n "$password") -stdin -salt "$salt" 2>/dev/null)
        
        if [[ "$encrypted" == "$salt_hash" ]]; then
            return 0
        fi
    fi

    return 1
}

get_user_sessions() {
    # Scans system directories for available Desktop Environments (.desktop files)
    local session_dirs=("/usr/share/xsessions" "/usr/share/wayland-sessions")
    local found_sessions=()

    for dir in "${session_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            for file in "$dir"/*.desktop; do
                if [[ -f "$file" ]]; then
                    local name
                    name=$(grep -E '^Name=' "$file" | head -n1 | cut -d= -f2)
                    local exec_cmd
                    exec_cmd=$(grep -E '^Exec=' "$file" | head -n1 | cut -d= -f2)
                    found_sessions+=("$name:$exec_cmd")
                fi
            done
        fi
    done

    # Output format: "Session Name|Exec Command"
    for session in "${found_sessions[@]}"; do
        echo "${session//:/\/}"
    done
}

launch_session() {
    local username="$1"
    local session_cmd="$2"

    log_message "INFO" "Initiating session launch for user: $username"

    # Get user details
    local user_uid
    user_uid=$(id -u "$username")
    local user_gid
    user_gid=$(id -g "$username")
    local user_home
    user_home=$(eval echo "~$username")

    # Set up basic runtime environment variables
    export HOME="$user_home"
    export USER="$username"
    export LOGNAME="$username"
    export SHELL=$(getent passwd "$username" | cut -d: -f7)
    export XDG_RUNTIME_DIR="/run/user/$user_uid"

    # Change to user home directory
    cd "$user_home"

    # Execute the session command as the logged-in user securely via runuser
    if command -v runuser &> /dev/null; then
        exec runuser -u "$username" -- env \
            HOME="$HOME" \
            USER="$USER" \
            LOGNAME="$LOGNAME" \
            SHELL="$SHELL" \
            XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
            $session_cmd
    else
        exec su - "$username" -c "$session_cmd"
    fi
}

# --- Main API Handler Layer ---
if [[ "${1:-}" == "--list-sessions" ]]; then
    get_user_sessions
    exit 0
fi

if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <username> <password> <exec_command>"
    exit 1
fi

USER_IN="$1"
PASS_IN="$2"
CMD_IN="$3"

if authenticate_user "$USER_IN" "$PASS_IN"; then
    log_message "SUCCESS" "User $USER_IN authenticated successfully."
    launch_session "$USER_IN" "$CMD_IN"
else
    log_message "WARNING" "Failed login attempt for user: $USER_IN"
    echo "AUTH_FAILURE"
    exit 1
fi
