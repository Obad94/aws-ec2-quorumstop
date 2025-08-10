#!/bin/bash
# ============================================
# AWS EC2 QuorumStop - Server-side Vote Handler (Enhanced)
# Adds --plain mode for environments without UTF-8/emoji support
# ============================================
# Installation:
# 1. Copy this file to /home/ubuntu/vote_shutdown.sh
# 2. Make executable: chmod +x /home/ubuntu/vote_shutdown.sh
# 3. (Optional) Symlink: sudo ln -sf /home/ubuntu/vote_shutdown.sh /usr/local/bin/vote_shutdown

VOTE_DIR="/tmp/shutdown_vote"
VOTE_TIMEOUT=60  # voting window in seconds
SHUTDOWN_DELAY=30  # seconds after unanimous pass before issuing shutdown
LOG_FILE="/var/log/quorumstop-votes.log"
PLAIN_MODE=0
TEAM_MAP_FILE="$HOME/.quorumstop/team.map"

# Parse optional flag first
if [[ "$1" == "--plain" || "$1" == "-p" ]]; then
  PLAIN_MODE=1
  shift
fi

# ============================================
# Team IP to Name Mappings (CONFIGURE THIS / FALLBACK ONLY)
# ============================================
# These are fallback defaults. They will be overridden if a dynamic team.map file is present.
# shellcheck disable=SC2034
declare -A DEV_NAMES
DEV_NAMES["203.0.113.10"]="Alice"     # Fallback Developer 1
DEV_NAMES["203.0.113.20"]="Bob"       # Fallback Developer 2  
DEV_NAMES["203.0.113.30"]="Carol"     # Fallback Developer 3

load_team_map() {
  # Load dynamic mappings from $TEAM_MAP_FILE if it exists, stripping CR to avoid display glitches.
  if [[ -f $TEAM_MAP_FILE ]]; then
    local loaded=0
    DEV_NAMES=()
    while IFS=$' \t' read -r ip name _rest; do
      [[ -z $ip || ${ip:0:1} == '#' ]] && continue
      ip=${ip%$'\r'}; ip=${ip//$'\n'/}
      name=${name%$'\r'}; name=${name//$'\n'/}
      [[ -z $name ]] && continue
      DEV_NAMES["$ip"]="$name"
      ((loaded++))
    done < <(tr -d '\r' < "$TEAM_MAP_FILE")
    if (( loaded > 0 )); then
      echo "[info] Loaded $loaded team entries from $TEAM_MAP_FILE" >&2
    else
      echo "[warn] team.map present but no valid entries parsed; using fallback defaults" >&2
    fi
  fi
}

load_team_map

# ============================================
# Helper Functions
# ============================================

emj() {
  # Return emoji or plain equivalent based on PLAIN_MODE
  local key="$1"
  if [[ $PLAIN_MODE -eq 1 ]]; then
    case "$key" in
      vote) echo "VOTE";;
      yes) echo "YES";;
      no) echo "NO";;
      warn) echo "WARN";;
      info) echo "INFO";;
      clock) echo "TIME";;
      pass) echo "PASS";;
      fail) echo "FAIL";;
      result) echo "RESULT";;
      save) echo "SAVE";;
      user) echo "USER";;
      shutdown) echo "SHUTDOWN";;
      *) echo "$key";;
    esac
  else
    case "$key" in
      vote) echo "🗳️";;
      yes) echo "✅";;
      no) echo "❌";;
      warn) echo "⚠️";;
      info) echo "ℹ️";;
      clock) echo "⏰";;
      pass) echo "🏁";;
      fail) echo "🛡️";;
      result) echo "📊";;
      save) echo "💾";;
      user) echo "👥";;
      shutdown) echo "📉";;
      *) echo "$key";;
    esac
  fi
}

get_connected_users() {
    who | awk '{print $5}' | tr -d '()' | sort -u | grep -v '^$'
}

get_dev_name() {
    local ip=$1
    local name="${DEV_NAMES[$ip]}"
    # Strip any stray CR / LF characters just in case (Windows CRLF uploads)
    name="${name//$'\r'/}"
    name="${name//$'\n'/}"
    if [[ -z $name ]]; then
      echo "Unknown($ip)"
    else
      echo "$name"
    fi
}

get_user_ip() {
    local user_ip=""
    if [[ -n $SSH_CLIENT ]]; then
        user_ip=$(awk '{print $1}' <<<"$SSH_CLIENT")
    elif [[ -n $SSH_CONNECTION ]]; then
        user_ip=$(awk '{print $1}' <<<"$SSH_CONNECTION")
    else
        user_ip=$(who am i | awk '{print $5}' | tr -d '()')
    fi
    echo "$user_ip"
}

send_vote_notification() {
    local initiator_name=$1
    local header="============================================"
    {
      echo "$header"
      echo "$(emj vote)  SERVER SHUTDOWN VOTE"
      echo "$header"
      echo "Initiated by: $initiator_name"
      echo "Reason: Save AWS costs"
      echo "Time: $(date '+%H:%M %Z')"
      echo ""
      echo "$(emj clock) You have $((VOTE_TIMEOUT / 60)) MINUTES to vote:"
      echo ""
      echo "$(emj yes) To AGREE to shutdown:"
      echo "   vote_shutdown yes"
      echo ""
      echo "$(emj no) To REJECT shutdown:"
      echo "   vote_shutdown no"
      echo ""
      echo "$(emj warn)  No vote = NO vote (server stays online)"
      echo "$header"
    } | wall 2>/dev/null || true
}

send_vote_update() {
    local user_name=$1 user_ip=$2 vote=$3
    local hint="Use: vote_shutdown yes | vote_shutdown no"
    if [[ $vote == "yes" ]]; then
        wall "$(emj vote)  VOTE UPDATE: $user_name ($user_ip) voted $(emj yes) YES  - $hint" 2>/dev/null || true
    else
        wall "$(emj vote)  VOTE UPDATE: $user_name ($user_ip) voted $(emj no) NO   - $hint" 2>/dev/null || true
    fi
}

send_final_results() {
    local yes_votes=$1 total_no=$2 non_voters=$3 result=$4
    local header="============================================"
    {
      echo "$header"
      echo "$(emj result) FINAL VOTING RESULTS"
      echo "$header"
      echo "$(emj yes) YES votes: $yes_votes"
      echo "$(emj no) NO votes: $total_no (including $non_voters non-voters)"
      echo "$header"
      if [[ $result == PASS ]]; then
        echo "$(emj pass) VOTE PASSED: Server will shutdown in 30 seconds!"
        echo "$(emj save) SAVE YOUR WORK NOW!"
      else
        echo "$(emj fail) VOTE FAILED: Server will continue running."
        echo "$(emj info) Team decided to keep server online."
      fi
      echo "$header"
    } | wall 2>/dev/null || true
}

log_vote() {
  local action="$1" user="$2" ip="$3" detail="$4"
  if [[ ! -f $LOG_FILE ]]; then
    (touch "$LOG_FILE" 2>/dev/null || sudo touch "$LOG_FILE" 2>/dev/null) && (chmod 640 "$LOG_FILE" 2>/dev/null || sudo chmod 640 "$LOG_FILE" 2>/dev/null)
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
    mkdir -p "$VOTE_DIR" && chmod 700 "$VOTE_DIR" 2>/dev/null || true
    echo "Debug: Detected IP: $user_ip, User: $user_name"
    case "$vote" in
        yes|y|YES|Y)
            echo yes >"$vote_file"
            echo "$(emj yes) Vote recorded: YES (agree to shutdown)"
            send_vote_update "$user_name" "$user_ip" "yes"
            log_vote "VOTE_CAST" "$user_name" "$user_ip" "yes"
            ;;
        no|n|NO|N)
            echo no >"$vote_file"
            echo "$(emj no) Vote recorded: NO (reject shutdown)"
            send_vote_update "$user_name" "$user_ip" "no"
            log_vote "VOTE_CAST" "$user_name" "$user_ip" "no"
            ;;
        *)
            echo "$(emj no) Invalid vote. Usage:" >&2
            echo "   vote_shutdown yes  (agree to shutdown)" >&2
            echo "   vote_shutdown no   (reject shutdown)" >&2
            log_vote "VOTE_INVALID" "$user_name" "$user_ip" "$vote"
            exit 1
            ;;
    esac
}

initiate_vote() {
    local initiator_ip=$1
    local initiator_name=$(get_dev_name "$initiator_ip")
    log_vote "VOTE_INITIATED" "$initiator_name" "$initiator_ip" "timeout=$VOTE_TIMEOUT plain=$PLAIN_MODE"
    echo "$(emj vote)  Starting vote initiated by $initiator_name ($initiator_ip)"
    mkdir -p "$VOTE_DIR" && chmod 700 "$VOTE_DIR" 2>/dev/null || true
    rm -f "$VOTE_DIR"/*
    # Auto-record initiator YES to reflect intent
    echo yes >"$VOTE_DIR/${initiator_name}_${initiator_ip}_vote"
    # Marker so late joiners can detect active vote
    echo 1 > "$VOTE_DIR/NOTICE_SENT"
    local connected_ips=($(get_connected_users))
    local other_users=0
    echo ""
    echo "$(emj user) Connected users:"
    for ip in "${connected_ips[@]}"; do
        local name=$(get_dev_name "$ip")
        if [[ $ip != "$initiator_ip" ]]; then
            echo "  - $name ($ip)"
            ((other_users++))
        else
            echo "  - $name ($ip) [INITIATOR]*"
        fi
    done
    if [[ $other_users -eq 0 ]]; then
        echo ""
        echo "$(emj yes) Only initiator connected. Safe to shutdown."
        log_vote "VOTE_AUTOPASS" "$initiator_name" "$initiator_ip" "solo"
        return 0
    fi
    send_vote_notification "$initiator_name"
    echo ""
    echo "$(emj clock) Waiting for votes... ($VOTE_TIMEOUT seconds)"
    local remaining=$VOTE_TIMEOUT
    while [[ $remaining -gt 0 ]]; do
        sleep 10
        remaining=$((remaining - 10))
        local current_votes=$(ls "$VOTE_DIR"/*_vote 2>/dev/null | wc -l | tr -d ' ')
        # Subtract the initiator's auto vote when displaying progress to users
        local progress=$(( current_votes - 1 ))
        echo "$(emj clock) Time remaining: ${remaining}s | $(emj vote) Votes received: $progress/$other_users"
        if [[ $progress -eq $other_users ]]; then
            echo "$(emj yes) All users voted! Processing results..."
            break
        fi
    done
    echo ""
    echo "$(emj result) Counting votes..."
    local yes_votes=0 no_votes=0
    for vote_file in "$VOTE_DIR"/*_vote; do
        [[ -f $vote_file ]] || continue
        local vote_content=$(head -n1 "$vote_file")
        local filename=$(basename "$vote_file")
        local voter=${filename%_vote}
        echo "  $voter: $vote_content"
        case "$vote_content" in
          yes) ((yes_votes++)) ;;
          no)  ((no_votes++)) ;;
        esac
    done
    local total_participants=$((other_users + 1))
    local non_voters=$((total_participants - yes_votes - no_votes))
    local total_no=$((no_votes + non_voters))
    echo ""
    echo "$(emj result) FINAL RESULTS:"
    echo "$(emj yes) YES votes: $yes_votes"
    echo "$(emj no) NO votes: $no_votes (explicit)"
    echo "$(emj info) Non-voters: $non_voters (counted as NO)"
    echo "$(emj result) Total NO: $total_no"
    echo "$(emj info) Required: ALL participants must vote YES (unanimous)"
    # Unanimous requirement: no explicit NO and no non-voters
    if [[ $total_no -eq 0 && $yes_votes -eq $total_participants ]]; then
        echo ""
        echo "$(emj pass) RESULT: VOTE PASSED - Unanimous approval, shutdown proceeding!"
        send_final_results "$yes_votes" "$total_no" "$non_voters" "PASS"
        log_vote "VOTE_RESULT" "$initiator_name" "$initiator_ip" "PASS unanimous yes=$yes_votes"
        echo "$(emj shutdown) Server will shutdown in $SHUTDOWN_DELAY seconds..."
        echo "$(emj save) SAVE YOUR WORK NOW!"
        # Grace period then attempt shutdown (multiple fallbacks)
        sleep "$SHUTDOWN_DELAY"
        if command -v shutdown >/dev/null 2>&1; then
          sudo shutdown -h now "QuorumStop unanimous vote"
        elif command -v systemctl >/dev/null 2>&1; then
          sudo systemctl poweroff
        elif command -v poweroff >/dev/null 2>&1; then
          sudo poweroff
        else
          echo "$(emj warn) Unable to locate shutdown command; please shut down manually." >&2
          log_vote "SHUTDOWN_FAIL" "$initiator_name" "$initiator_ip" "no_shutdown_command"
        fi
        rm -rf "$VOTE_DIR"
        return 0
    else
        echo ""
        echo "$(emj fail) RESULT: VOTE FAILED - Not unanimous, shutdown cancelled."
        send_final_results "$yes_votes" "$total_no" "$non_voters" "FAIL"
        log_vote "VOTE_RESULT" "$initiator_name" "$initiator_ip" "FAIL yes=$yes_votes no=$total_no"
        rm -rf "$VOTE_DIR"
        return 1
    fi
}

show_debug_info() {
    echo "=== $(emj info) DEBUG INFORMATION ==="
    echo ""
    echo "$(emj info) Network Connection Detection:"
    echo "  SSH_CLIENT: $SSH_CLIENT"
    echo "  SSH_CONNECTION: $SSH_CONNECTION" 
    echo "  who am i: $(who am i)"
    echo ""
    echo "IP Detection Methods:"
    if [[ -n $SSH_CLIENT ]]; then echo "  ✓ SSH_CLIENT: $(awk '{print $1}' <<<"$SSH_CLIENT")"; else echo "  x SSH_CLIENT: Not available"; fi
    if [[ -n $SSH_CONNECTION ]]; then echo "  ✓ SSH_CONNECTION: $(awk '{print $1}' <<<"$SSH_CONNECTION")"; else echo "  x SSH_CONNECTION: Not available"; fi
    echo "  who am i: $(who am i | awk '{print $5}' | tr -d '()')"
    echo ""
    echo "Active Connections (who):"
    who | sed 's/^/    /'
    echo ""
    echo "Connected IP Addresses:"
    get_connected_users | sed 's/^/    /'
    echo ""
    echo "Team Member Mappings:"
    for ip in "${!DEV_NAMES[@]}"; do
        echo "  $ip -> ${DEV_NAMES[$ip]}"
    done
    echo ""
    echo "Vote Directory: $VOTE_DIR"
    if [[ -d $VOTE_DIR ]]; then
        echo "  Directory exists: YES"
        if ls -A "$VOTE_DIR" >/dev/null 2>&1; then
            echo "  Vote files:"; ls -la "$VOTE_DIR/" | sed 's/^/    /'
        else
            echo "  No vote files found"
        fi
    else
        echo "  Directory exists: NO"
    fi
    echo ""
    echo "Plain mode: $PLAIN_MODE"
    echo "Script ready."
}

show_status() {
    if [[ -d $VOTE_DIR ]] && ls "$VOTE_DIR"/*_vote >/dev/null 2>&1; then
        echo "$(emj vote) Active voting session detected:"
        echo ""
        echo "Vote directory: $VOTE_DIR"
        echo "Current votes:"
        ls -la "$VOTE_DIR" | sed 's/^/  /'
        echo ""
        echo "Vote contents:"
        for vote_file in "$VOTE_DIR"/*_vote; do
            [[ -f $vote_file ]] || continue
            local voter=$(basename "$vote_file" _vote)
            local vote_content=$(cat "$vote_file")
            echo "  $voter: $vote_content"
        done
    else
        echo "No active voting session."
        echo "Run 'vote_shutdown initiate <your_ip>' to start a vote."
    fi
}

show_usage() {
    echo "AWS EC2 QuorumStop - Server-side Vote Handler"
    echo ""
    echo "USAGE:"
    echo "  vote_shutdown [--plain|-p] yes            Cast YES vote (agree to shutdown)"
    echo "  vote_shutdown [--plain|-p] no             Cast NO vote (reject shutdown)" 
    echo "  vote_shutdown [--plain|-p] initiate <ip>  Start voting (system use only)"
    echo "  vote_shutdown [--plain|-p] status         Check current voting status"
    echo "  vote_shutdown [--plain|-p] debug          Show connection debug info"
    echo "  vote_shutdown help                        Show this help"
    echo ""
    echo "VOTING PROCESS:"
    echo "  1. Windows script initiates vote"
    echo "  2. Notifications broadcast to all connected users"
    echo "  3. Users vote within the time limit (default: 5 minutes)"
    echo "  4. UNANIMOUS YES required to shutdown"
    echo "  5. Any NO or missing vote keeps server online"
    echo ""
    echo "DECISION RULES:" 
    echo "  - All connected participants must vote YES"
    echo "  - Any NO (explicit) or non-vote counts as NO -> vote fails"
    echo "  - Solo initiator (no others connected) => auto-pass"
    echo ""
    echo "CONFIGURATION:"
    echo "  Update DEV_NAMES array within script"
    echo "  Keep sync with Windows config for readability"
    echo ""
    echo "OPTIONS:"
    echo "  --plain / -p  Disable emojis for minimal terminals"
}

# ============================================
# Main Script Logic
# ============================================

case "$1" in
    "initiate")
        shift
        if [[ -z $1 ]]; then
            echo "Error: Missing initiator IP address" >&2
            echo "Usage: vote_shutdown initiate <ip_address>" >&2
            exit 1
        fi
        initiate_vote "$1"
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
