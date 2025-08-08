# Configuration Guide

This guide covers all configuration options for customizing AWS EC2 QuorumStop for your team's specific needs.

## 🔧 Overview

The system has two main configuration points:
- **Client-side**: `config.bat` (Windows batch scripts)
- **Server-side**: `vote_shutdown.sh` (EC2 instance)

## 💻 Client-Side Configuration

### Core Settings (`config.bat`)

```batch
@echo off
REM ============================================
REM AWS EC2 QuorumStop - Configuration
REM ============================================

REM =============================
REM AWS Configuration
REM =============================
set INSTANCE_ID=i-0123456789abcdef0      # Your EC2 instance ID
set AWS_REGION=us-west-2                 # Your AWS region

REM =============================
REM Server Connection (Dynamic)
REM =============================
set SERVER_IP=1.2.3.4                   # Auto-updated by scripts
set KEY_FILE=C:\Users\%USERNAME%\Downloads\your-key.pem  # SSH private key path

REM =============================
REM Team IP Mappings
REM =============================
set DEV1_IP=203.0.113.10                # Developer 1 public IP
set DEV2_IP=203.0.113.20                # Developer 2 public IP  
set DEV3_IP=203.0.113.30                # Developer 3 public IP
set DEV4_IP=203.0.113.40                # Developer 4 public IP (optional)
set DEV5_IP=203.0.113.50                # Developer 5 public IP (optional)

REM =============================
REM Current User Configuration  
REM =============================
set YOUR_NAME=Developer1                # Your name (for identification)
set YOUR_IP=%DEV1_IP%                   # Your IP (should match one above)

REM =============================
REM Server Configuration
REM =============================
set SERVER_VOTE_SCRIPT=/home/ubuntu/vote_shutdown.sh  # Server script path
set SERVER_USER=ubuntu                  # SSH username
```

### Configuration for Different Team Sizes

**Small Team (2-3 developers):**
```batch
REM Simple setup for small teams
set DEV1_IP=203.0.113.10
set DEV2_IP=203.0.113.20
set DEV3_IP=203.0.113.30

REM Leave others empty/unused
set DEV4_IP=0.0.0.0
set DEV5_IP=0.0.0.0
```

**Medium Team (4-6 developers):**
```batch
REM Extended team configuration
set DEV1_IP=203.0.113.10
set DEV2_IP=203.0.113.20
set DEV3_IP=203.0.113.30
set DEV4_IP=203.0.113.40
set DEV5_IP=203.0.113.50
set DEV6_IP=203.0.113.60

REM Add more as needed
set ALICE_IP=%DEV1_IP%
set BOB_IP=%DEV2_IP%
set CAROL_IP=%DEV3_IP%
set DAVE_IP=%DEV4_IP%
set EVE_IP=%DEV5_IP%
set FRANK_IP=%DEV6_IP%
```

**Large Team (7+ developers):**
```batch
REM For larger teams, consider multiple subnets or ranges
REM Frontend team
set FRONTEND_DEV1_IP=203.0.113.10
set FRONTEND_DEV2_IP=203.0.113.20
set FRONTEND_DEV3_IP=203.0.113.30

REM Backend team  
set BACKEND_DEV1_IP=203.0.113.40
set BACKEND_DEV2_IP=203.0.113.50
set BACKEND_DEV3_IP=203.0.113.60

REM DevOps team
set DEVOPS_DEV1_IP=203.0.113.70
set DEVOPS_DEV2_IP=203.0.113.80
```

### Per-Developer Configuration

Each team member should customize these settings in their `config.bat`:

**Alice's config:**
```batch
set YOUR_NAME=Alice
set YOUR_IP=%DEV1_IP%
```

**Bob's config:**
```batch  
set YOUR_NAME=Bob
set YOUR_IP=%DEV2_IP%
```

**Carol's config:**
```batch
set YOUR_NAME=Carol
set YOUR_IP=%DEV3_IP%
```

### Advanced Client Settings

**Timeout Configuration:**
```batch
REM Custom timeouts (optional - modify scripts if needed)
set SSH_TIMEOUT=60                      # SSH connection timeout
set VOTE_CHECK_INTERVAL=15              # How often to check vote status
set MAX_STARTUP_WAIT=300                # Max time to wait for server start
```

**Custom Paths:**
```batch
REM Alternative paths for different setups
set KEY_FILE=D:\AWS-Keys\production-key.pem      # Custom key location
set AWS_CLI_PATH=C:\Program Files\Amazon\AWSCLIV2\aws.exe  # Custom AWS CLI path
set TEMP_DIR=C:\Temp\QuorumStop                  # Custom temp directory
```

**Multi-Environment Support:**
```batch
REM Different environments
if "%ENVIRONMENT%"=="production" (
    set INSTANCE_ID=i-prod123456789abcdef0
    set AWS_REGION=us-east-1
    set KEY_FILE=C:\Keys\prod-key.pem
) else if "%ENVIRONMENT%"=="staging" (
    set INSTANCE_ID=i-stage123456789abcdef0
    set AWS_REGION=us-west-2
    set KEY_FILE=C:\Keys\staging-key.pem
) else (
    set INSTANCE_ID=i-dev123456789abcdef0
    set AWS_REGION=us-west-2
    set KEY_FILE=C:\Keys\dev-key.pem
)
```

## 🖥️ Server-Side Configuration

### Team Member Mapping (`vote_shutdown.sh`)

Edit the `DEV_NAMES` array in `/home/ubuntu/vote_shutdown.sh`:

```bash
# ============================================
# Team IP to Name Mappings (CONFIGURE THIS)
# ============================================
declare -A DEV_NAMES

# Core team members
DEV_NAMES["203.0.113.10"]="Alice"       # Frontend Lead
DEV_NAMES["203.0.113.20"]="Bob"         # Backend Developer
DEV_NAMES["203.0.113.30"]="Carol"       # DevOps Engineer

# Extended team (add as needed)
DEV_NAMES["203.0.113.40"]="Dave"        # QA Engineer  
DEV_NAMES["203.0.113.50"]="Eve"         # UI/UX Designer
DEV_NAMES["203.0.113.60"]="Frank"       # Data Scientist

# Contractors/temporary members
DEV_NAMES["203.0.113.70"]="Consultant1" # External consultant
DEV_NAMES["203.0.113.80"]="Intern1"     # Summer intern
```

### Voting Behavior Configuration

**Timing Settings:**
```bash
# Voting window duration (in seconds)
VOTE_TIMEOUT=300                        # 5 minutes (default)
# VOTE_TIMEOUT=180                      # 3 minutes (faster)
# VOTE_TIMEOUT=600                      # 10 minutes (more time)

# Grace period before shutdown (in seconds)
GRACE_PERIOD=30                         # 30 seconds (default)
# GRACE_PERIOD=60                       # 1 minute (more time to save)
# GRACE_PERIOD=10                       # 10 seconds (faster)
```

**Notification Frequency:**
```bash
# How often to show voting progress (in seconds)
PROGRESS_INTERVAL=10                    # Every 10 seconds (default)
# PROGRESS_INTERVAL=15                  # Every 15 seconds
# PROGRESS_INTERVAL=30                  # Every 30 seconds
```

**Quorum Rules:**
```bash
# Voting logic - customize based on team needs
calculate_result() {
    local yes_votes=$1
    local no_votes=$2
    local non_voters=$3
    
    # Option 1: Unanimous consent required (safest)
    local total_users=$((yes_votes + no_votes + non_voters))
    if [ $yes_votes -eq $total_users ] && [ $total_users -gt 0 ]; then
        return 0  # PASS
    else
        return 1  # FAIL
    fi
    
    # Option 2: Simple majority (alternative)
    # local total_votes=$((yes_votes + no_votes + non_voters))
    # local majority=$((total_votes / 2 + 1))
    # if [ $yes_votes -ge $majority ]; then
    #     return 0  # PASS
    # else
    #     return 1  # FAIL
    # fi
    
    # Option 3: Supermajority (2/3 required)
    # local total_votes=$((yes_votes + no_votes + non_voters))
    # local supermajority=$((total_votes * 2 / 3))
    # if [ $yes_votes -gt $supermajority ]; then
    #     return 0  # PASS
    # else
    #     return 1  # FAIL
    # fi
}
```

### Custom Notification Messages

**Personalized Messages:**
```bash
send_vote_notification() {
    local initiator_name=$1
    local custom_message=$2
    
    wall "============================================"
    wall "🗳️  SERVER SHUTDOWN VOTE"
    wall "============================================"
    wall "Initiated by: $initiator_name"
    wall "Reason: ${custom_message:-Save AWS costs}"  # Custom or default
    wall "Time: $(date '+%H:%M %Z')"
    # ... rest of notification
}
```

**Multi-language Support:**
```bash
# Language configuration
LANGUAGE=${LANG:-"en_US"}

case "$LANGUAGE" in
    "es_ES"|"es"*)
        VOTE_MSG="VOTACIÓN PARA APAGAR SERVIDOR"
        YES_MSG="Para APROBAR el apagado: vote_shutdown yes"
        NO_MSG="Para RECHAZAR el apagado: vote_shutdown no"
        ;;
    "fr_FR"|"fr"*)
        VOTE_MSG="VOTE POUR ARRÊTER LE SERVEUR"
        YES_MSG="Pour APPROUVER l'arrêt: vote_shutdown yes"
        NO_MSG="Pour REJETER l'arrêt: vote_shutdown no"
        ;;
    *)
        VOTE_MSG="SERVER SHUTDOWN VOTE"
        YES_MSG="To AGREE to shutdown: vote_shutdown yes"
        NO_MSG="To REJECT shutdown: vote_shutdown no"
        ;;
esac
```

## 🏢 Multi-Team Configurations

### Separate Instances per Team

**Team Frontend (`config-frontend.bat`):**
```batch
set INSTANCE_ID=i-frontend123456789abc
set AWS_REGION=us-west-2
set YOUR_TEAM=Frontend

set ALICE_IP=203.0.113.10
set BOB_IP=203.0.113.20
set CAROL_IP=203.0.113.30
```

**Team Backend (`config-backend.bat`):**
```batch
set INSTANCE_ID=i-backend123456789def
set AWS_REGION=us-east-1  
set YOUR_TEAM=Backend

set DAVE_IP=203.0.113.40
set EVE_IP=203.0.113.50
set FRANK_IP=203.0.113.60
```

### Shared Instance with Team Roles

**Role-based voting:**
```bash
# In vote_shutdown.sh
declare -A DEV_ROLES
DEV_ROLES["203.0.113.10"]="lead"        # Team lead has veto power
DEV_ROLES["203.0.113.20"]="senior"      # Senior developers
DEV_ROLES["203.0.113.30"]="senior"
DEV_ROLES["203.0.113.40"]="junior"      # Junior developers
DEV_ROLES["203.0.113.50"]="junior"

# Custom voting logic with roles
calculate_result_with_roles() {
    local lead_votes=0
    local senior_yes=0
    local total_seniors=0
    
    # Count votes by role
    for vote_file in "$VOTE_DIR"/*_vote; do
        if [ -f "$vote_file" ]; then
            local voter_ip=$(echo "$vote_file" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+')
            local role="${DEV_ROLES[$voter_ip]}"
            local vote=$(cat "$vote_file")
            
            case "$role" in
                "lead")
                    if [ "$vote" = "no" ]; then
                        return 1  # Lead veto power
                    fi
                    ;;
                "senior")
                    ((total_seniors++))
                    if [ "$vote" = "yes" ]; then
                        ((senior_yes++))
                    fi
                    ;;
            esac
        fi
    done
    
    # Require majority of seniors to approve
    if [ $senior_yes -gt $((total_seniors / 2)) ]; then
        return 0  # PASS
    else
        return 1  # FAIL
    fi
}
```

## 🕒 Time-Based Configurations

### Working Hours Enforcement

```bash
# Only allow voting during work hours
check_working_hours() {
    local current_hour=$(date +%H)
    local current_day=$(date +%u)  # 1=Monday, 7=Sunday
    
    # Monday-Friday, 8 AM - 6 PM
    if [ $current_day -le 5 ] && [ $current_hour -ge 8 ] && [ $current_hour -lt 18 ]; then
        return 0  # Working hours
    else
        return 1  # Non-working hours
    fi
}

initiate_vote() {
    if ! check_working_hours; then
        wall "⏰ Shutdown votes only allowed during working hours (8 AM - 6 PM, Mon-Fri)"
        return 1
    fi
    # ... rest of voting logic
}
```

### Timezone-Aware Configuration

```bash
# Multi-timezone team support
declare -A DEV_TIMEZONES
DEV_TIMEZONES["203.0.113.10"]="America/New_York"    # Alice (EST)
DEV_TIMEZONES["203.0.113.20"]="Europe/London"       # Bob (GMT)
DEV_TIMEZONES["203.0.113.30"]="Asia/Tokyo"          # Carol (JST)

show_time_for_all() {
    echo "Current time for team members:"
    for ip in "${!DEV_TIMEZONES[@]}"; do
        local name="${DEV_NAMES[$ip]}"
        local tz="${DEV_TIMEZONES[$ip]}"
        local time=$(TZ="$tz" date '+%H:%M %Z')
        echo "  $name: $time"
    done
}
```

## 🔧 Environment-Specific Configurations

### Development vs Production

**Development Environment:**
```bash
# Relaxed settings for development
VOTE_TIMEOUT=60              # Shorter voting window
GRACE_PERIOD=10             # Quick shutdown
DEBUG_MODE=true             # Verbose logging
ALLOW_FORCE_SHUTDOWN=true   # Allow emergency shutdown
```

**Production Environment:**
```bash
# Strict settings for production
VOTE_TIMEOUT=600            # Longer voting window
GRACE_PERIOD=120            # More time to save work
DEBUG_MODE=false            # Minimal logging
ALLOW_FORCE_SHUTDOWN=false  # No emergency shutdown
REQUIRE_ALL_USERS=true      # Unanimous consent required
```

### Cost Optimization Settings

**Aggressive Cost Savings:**
```bash
# Automatically shutdown if idle
AUTO_SHUTDOWN_IDLE=true
IDLE_THRESHOLD=3600         # 1 hour of inactivity
CHECK_INTERVAL=300          # Check every 5 minutes

# Schedule automatic shutdown
SCHEDULED_SHUTDOWN="18:00"  # 6 PM daily
WEEKEND_SHUTDOWN=true       # Always shutdown weekends
```

**Balanced Approach:**
```bash
# Moderate cost savings
AUTO_SHUTDOWN_IDLE=false    # Manual control only
SCHEDULED_REMINDER="17:30"  # Remind team at 5:30 PM
WEEKEND_REMINDER=true       # Remind about weekend costs
```

## 🧪 Testing Configurations

### Test Mode Settings

```bash
# Enable test mode
TEST_MODE=true
TEST_VOTE_TIMEOUT=30        # 30 seconds for testing
TEST_GRACE_PERIOD=5         # 5 seconds grace period
TEST_SIMULATE_USERS=3       # Simulate 3 connected users

# Test with dummy data
if [ "$TEST_MODE" = true ]; then
    # Override real user detection with test data
    get_connected_users()