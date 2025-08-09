#!/bin/bash
# ============================================
# AWS EC2 QuorumStop - Server-side Vote Handler
# Handles team voting logic on the EC2 instance
# ============================================
# Installation:
# 1. Copy this file to /home/ubuntu/vote_shutdown.sh
# 2. Make executable: chmod +x /home/ubuntu/vote_shutdown.sh
# 3. Create symlink: sudo ln -sf /home/ubuntu/vote_shutdown.sh /usr/local/bin/vote_shutdown

VOTE_DIR="/tmp/shutdown_vote"
VOTE_TIMEOUT=300  # 5 minutes voting window
LOG_FILE="/var/log/quorumstop-votes.log"

# ============================================
# Team IP to Name Mappings (CONFIGURE THIS)
# ============================================
# Add your team members' public IP addresses and names
# Get IPs from: https://whatismyipaddress.com
declare -A DEV_NAMES
DEV_NAMES["203.0.113.10"]="Alice"     # Developer 1
DEV_NAMES["203.0.113.20"]="Bob"       # Developer 2  
DEV_NAMES["203.0.113.30"]="Carol"     # Developer 3
# Add more team members as needed:
# DEV_NAMES["203.0.113.40"]="Dave"
# DEV_NAMES["203.0.113.50"]="Eve"

# ============================================
# Helper Functions
# ============================================

get_connected_users() {
    # Get active SSH connections IPs (from 'who')
    who | awk '{print $5}' | tr -d '()' | sort | uniq | grep -v "^$"
}

get_dev_name() {
    local ip=$1
    # Return friendly name if IP is mapped, otherwise show IP
    echo "${DEV_NAMES[$ip]:-Unknown($ip)}"
}

get_user_ip() {
    # Get current user's IP address using multiple methods
    local user_ip=""
    
    # Method 1: SSH_CLIENT environment variable (most reliable)
    if [ -n "$SSH_CLIENT" ]; then
        user_ip=$(echo $SSH_CLIENT | awk '{print $1}')
    # Method 2: SSH_CONNECTION environment variable  
    elif [ -n "$SSH_CONNECTION" ]; then
        user_ip=$(echo $SSH_CONNECTION | awk '{print $1}')
    # Method 3: Fallback to who command
    else
        user_ip=$(who am i | awk '{print $5}' | tr -d '()')
    fi
    
    echo "$user_ip"
}

send_vote_notification() {
    local initiator_name=$1
    
    # Send notification to all logged-in users via wall command
    wall "============================================"
    wall "🗳️  SERVER SHUTDOWN VOTE"
    wall "============================================"
    wall "Initiated by: $initiator_name"
    wall "Reason: Save AWS costs"
    wall "Time: $(date '+%H:%M %Z')"
    wall ""
    wall "⏰ You have $(($VOTE_TIMEOUT / 60)) MINUTES to vote:"
    wall ""
    wall "✅ To AGREE to shutdown:"
    wall "   vote_shutdown yes"
    wall ""
    wall "❌ To REJECT shutdown:"
    wall "   vote_shutdown no"
    wall ""
    wall "⚠️  No vote = NO vote (server stays online)"
    wall "============================================"
}

send_vote_update() {
    local user_name=$1
    local user_ip=$2
    local vote=$3
    
    if [ "$vote" = "yes" ]; then
        wall "🗳️  VOTE UPDATE: $user_name ($user_ip) voted ✅ YES (agree to shutdown)"
    else
        wall "🗳️  VOTE UPDATE: $user_name ($user_ip) voted ❌ NO (reject shutdown)"
    fi
}

send_final_results() {
    local yes_votes=$1
    local total_no=$2
    local non_voters=$3
    local result=$4
    
    wall "============================================"
    wall "📊 FINAL VOTING RESULTS"
    wall "============================================"
    wall "✅ YES votes: $yes_votes"
    wall "❌ NO votes: $total_no (including $non_voters non-voters)"
    wall "============================================"
    
    if [ "$result" = "PASS" ]; then
        wall "🏁 VOTE PASSED: Server will shutdown in 30 seconds!"
        wall "💾 SAVE YOUR WORK NOW!"
    else
        wall "🛡️  VOTE FAILED: Server will continue running."
        wall "💰 Team decided to keep server online."
    fi
    
    wall "============================================"
}

log_vote() {
  local action="$1" user="$2" ip="$3" detail="$4"
  # Ensure log file directory exists and has safe perms
  if [ ! -f "$LOG_FILE" ]; then
    sudo touch "$LOG_FILE" 2>/dev/null || touch "$LOG_FILE" 2>/dev/null
    sudo chmod 640 "$LOG_FILE" 2>/dev/null || chmod 640 "$LOG_FILE" 2>/dev/null
  fi
  printf '%s | %s | %s | %s | %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$action" "$user" "$ip" "$detail" >> "$LOG_FILE" 2>/dev/null || true
}

# ============================================
# Main Functions
# ============================================

handle_vote() {
    local vote=$1
    local user_ip=$(get_user_ip)
    local user_name=$(get_dev_name "$user_ip")
    local vote_file="$VOTE_DIR/${user_name}_${user_ip}_vote"
    
    # Ensure secure vote directory
    mkdir -p "$VOTE_DIR"
    chmod 700 "$VOTE_DIR" 2>/dev/null || true

    # Debug output for troubleshooting
    echo "Debug: Detected IP: $user_ip, User: $user_name"
    
    case "$vote" in
        yes|y|YES|Y)
            echo "yes" > "$vote_file"
            echo "✅ Vote recorded: YES (agree to shutdown)"
            send_vote_update "$user_name" "$user_ip" "yes"
            log_vote "VOTE_CAST" "$user_name" "$user_ip" "yes"
            ;;
        no|n|NO|N)
            echo "no" > "$vote_file"
            echo "❌ Vote recorded: NO (reject shutdown)"
            send_vote_update "$user_name" "$user_ip" "no"
            log_vote "VOTE_CAST" "$user_name" "$user_ip" "no"
            ;;
        *)
            echo "❌ Invalid vote. Usage:"
            echo "   vote_shutdown yes  (agree to shutdown)"
            echo "   vote_shutdown no   (reject shutdown)"
            log_vote "VOTE_INVALID" "$user_name" "$user_ip" "$vote"
            exit 1
            ;;
    esac
}

initiate_vote() {
    local initiator_ip=$1
    local initiator_name=$(get_dev_name "$initiator_ip")
    log_vote "VOTE_INITIATED" "$initiator_name" "$initiator_ip" "timeout=$VOTE_TIMEOUT"
    
    echo "🗳️  Starting vote initiated by $initiator_name ($initiator_ip)"
    
    # Clean up any previous voting session
    mkdir -p "$VOTE_DIR"
    chmod 700 "$VOTE_DIR" 2>/dev/null || true
    rm -f "$VOTE_DIR"/*
    
    # Get list of connected users
    local connected_ips=($(get_connected_users))
    local other_users=0
    
    echo ""
    echo "👥 Connected users:"
    for ip in "${connected_ips[@]}"; do
        local name=$(get_dev_name "$ip")
        if [ "$ip" != "$initiator_ip" ]; then
            echo "  - $name ($ip)"
            ((other_users++))
        else
            echo "  - $name ($ip) [INITIATOR]"
        fi
    done
    
    # If only initiator is connected, safe to shutdown immediately
    if [ $other_users -eq 0 ]; then
        echo ""
        echo "✅ Only initiator connected. Safe to shutdown."
        log_vote "VOTE_AUTOPASS" "$initiator_name" "$initiator_ip" "solo"
        return 0
    fi
    
    # Send vote notification to all users
    send_vote_notification "$initiator_name"
    echo ""
    echo "⏰ Waiting for votes... ($VOTE_TIMEOUT seconds)"
    
    # Voting countdown loop
    local remaining=$VOTE_TIMEOUT
    while [ $remaining -gt 0 ]; do
        sleep 10
        remaining=$((remaining - 10))
        local current_votes=$(ls "$VOTE_DIR"/*_vote 2>/dev/null | wc -l)
        
        echo "⏰ Time remaining: ${remaining}s | 🗳️  Votes received: $current_votes/$other_users"
        
        # If all users voted, end voting early
        if [ $current_votes -eq $other_users ]; then
            echo "✅ All users voted! Processing results..."
            break
        fi
    done
    
    echo ""
    echo "📊 Counting votes..."
    
    # Count votes
    local yes_votes=0
    local no_votes=0
    
    for vote_file in "$VOTE_DIR"/*_vote; do
        if [ -f "$vote_file" ]; then
            local vote_content=$(head -n1 "$vote_file")
            local filename=$(basename "$vote_file")
            local voter=$(echo "$filename" | cut -d'_' -f1)
            
            echo "  $voter: $vote_content"
            
            if [ "$vote_content" = "yes" ]; then
                ((yes_votes++))
            elif [ "$vote_content" = "no" ]; then
                ((no_votes++))
            fi
        fi
    done
    
    # Calculate results (non-voters count as NO)
    local non_voters=$((other_users - yes_votes - no_votes))
    local total_no=$((no_votes + non_voters))
    
    echo ""
    echo "📊 FINAL RESULTS:"
    echo "✅ YES votes: $yes_votes"
    echo "❌ NO votes: $no_votes (explicit)"
    echo "😶 Non-voters: $non_voters (counted as NO)"
    echo "📈 Total NO: $total_no"
    echo "🎯 Required: YES votes must exceed total NO votes"
    
    # Make decision: YES must be greater than total NO
    if [ $yes_votes -gt $total_no ]; then
        echo ""
        echo "🏁 RESULT: VOTE PASSED - Shutdown approved!"
        send_final_results "$yes_votes" "$total_no" "$non_voters" "PASS"
        log_vote "VOTE_RESULT" "$initiator_name" "$initiator_ip" "PASS yes=$yes_votes no=$total_no"
        sleep 30  # Grace period for users to save work
        rm -rf "$VOTE_DIR"
        return 0  # Success - proceed with shutdown
    else
        echo ""
        echo "🛡️  RESULT: VOTE FAILED - Shutdown rejected!"
        send_final_results "$yes_votes" "$total_no" "$non_voters" "FAIL"
        log_vote "VOTE_RESULT" "$initiator_name" "$initiator_ip" "FAIL yes=$yes_votes no=$total_no"
        rm -rf "$VOTE_DIR"
        return 1  # Failure - do not shutdown
    fi
}

show_debug_info() {
    echo "=== 🔍 DEBUG INFORMATION ==="
    echo ""
    echo "🌐 Network Connection Detection:"
    echo "  SSH_CLIENT: $SSH_CLIENT"
    echo "  SSH_CONNECTION: $SSH_CONNECTION" 
    echo "  who am i: $(who am i)"
    echo ""
    echo "📍 IP Detection Methods:"
    if [ -n "$SSH_CLIENT" ]; then
        echo "  ✅ SSH_CLIENT method: $(echo $SSH_CLIENT | awk '{print $1}')"
    else
        echo "  ❌ SSH_CLIENT method: Not available"
    fi
    if [ -n "$SSH_CONNECTION" ]; then
        echo "  ✅ SSH_CONNECTION method: $(echo $SSH_CONNECTION | awk '{print $1}')"
    else
        echo "  ❌ SSH_CONNECTION method: Not available"
    fi
    echo "  ℹ️  who am i method: $(who am i | awk '{print $5}' | tr -d '()')"
    echo ""
    echo "👥 Active Connections (from 'who'):"
    who | sed 's/^/    /'
    echo ""
    echo "🔗 Connected IP Addresses (from 'who'):"
    who | awk '{print $5}' | tr -d '()' | sort | uniq | sed 's/^/    /'
    echo ""
    echo "👨‍👩‍👧‍👦 Team Member Mappings:"
    for ip in "${!DEV_NAMES[@]}"; do
        echo "  $ip → ${DEV_NAMES[$ip]}"
    done
    echo ""
    echo "📁 Vote Directory: $VOTE_DIR"
    if [ -d "$VOTE_DIR" ]; then
        echo "  Directory exists: ✅"
        if [ "$(ls -A "$VOTE_DIR" 2>/dev/null)" ]; then
            echo "  Vote files:"
            ls -la "$VOTE_DIR/" | sed 's/^/    /'
        else
            echo "  No vote files found"
        fi
    else
        echo "  Directory exists: ❌"
    fi
    echo ""
    echo "✅ Script is ready for democratic voting!"
}

show_status() {
    if [ -d "$VOTE_DIR" ] && [ "$(ls -A "$VOTE_DIR" 2>/dev/null)" ]; then
        echo "🗳️  Active voting session detected:"
        echo ""
        echo "📁 Vote directory: $VOTE_DIR"
        echo "📊 Current votes:"
        ls -la "$VOTE_DIR" | sed 's/^/  /'
        echo ""
        echo "🔍 Vote contents:"
        for vote_file in "$VOTE_DIR"/*_vote; do
            if [ -f "$vote_file" ]; then
                local voter=$(basename "$vote_file" _vote)
                local vote_content=$(cat "$vote_file")
                echo "  $voter: $vote_content"
            fi
        done
    else
        echo "ℹ️  No active voting session."
        echo "   Run 'vote_shutdown initiate <your_ip>' to start a vote."
    fi
}

show_usage() {
    echo "AWS EC2 QuorumStop - Server-side Vote Handler"
    echo ""
    echo "📖 USAGE:"
    echo "  vote_shutdown yes             - Cast YES vote (agree to shutdown)"
    echo "  vote_shutdown no              - Cast NO vote (reject shutdown)" 
    echo "  vote_shutdown initiate <ip>   - Start voting (system use only)"
    echo "  vote_shutdown status          - Check current voting status"
    echo "  vote_shutdown debug           - Show connection debug info"
    echo ""
    echo "🗳️  VOTING PROCESS:"
    echo "  1. Someone runs shutdown on their Windows machine"
    echo "  2. This script sends notifications to all connected users"
    echo "  3. Users vote within the time limit (default: 5 minutes)"
    echo "  4. Majority YES votes = shutdown approved"
    echo "  5. Majority NO/non-votes = shutdown rejected"
    echo ""
    echo "⚖️  DECISION RULES:"
    echo "  - YES votes must exceed total NO votes to pass"
    echo "  - Non-voters are counted as NO votes (safe default)"
    echo "  - Ties result in keeping server running"
    echo ""
    echo "🔧 CONFIGURATION:"
    echo "  Edit DEV_NAMES array in this script to add team members"
    echo "  Format: DEV_NAMES[\"IP_ADDRESS\"]=\"Name\""
}

# ============================================
# Main Script Logic
# ============================================

case "$1" in
    "initiate")
        if [ -z "$2" ]; then
            echo "❌ Error: Missing initiator IP address"
            echo "Usage: vote_shutdown initiate <ip_address>"
            exit 1
        fi
        initiate_vote "$2"
        ;;
    "yes"|"y"|"YES"|"Y"|"no"|"n"|"NO"|"N")
        handle_vote "$1"
        ;;
    "debug")
        show_debug_info
        ;;
    "status")
        show_status
        ;;
    "help"|"--help"|"-h")
        show_usage
        ;;
    *)
        show_usage
        exit 1
        ;;
 esac
