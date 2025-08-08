# Usage Guide

This guide covers daily operations and common workflows with AWS EC2 QuorumStop.

## 🚀 Quick Reference

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `scripts/start_server.bat` | Start EC2 instance | Beginning of work day |
| `scripts/shutdown_server.bat` | Request team shutdown | End of work day |
| `scripts/view_config.bat` | Show configuration | Check settings/IP |
| `scripts/test_aws.bat` | Test AWS connectivity | Troubleshooting |

## 🗓️ Daily Workflow

### 🌅 Starting Your Work Day

1. **Start the server**:
   ```batch
   scripts/start_server.bat
   ```

2. **Expected output**:
   ```
   === AWS EC2 QuorumStop - Server Startup ===
   [1/3] Checking current server status...
   Current server status: [stopped]
   [2/3] Server is stopped. Starting now...
   SUCCESS: Start command sent to AWS
   [3/3] Waiting for server to become running...
   SUCCESS: Server is now running!
   New server IP: 52.89.123.45
   Configuration updated successfully!
   Server is ready for use!
   ```

3. **Connect to your server**:
   ```batch
   ssh -i "C:\Users\YourName\Downloads\your-key.pem" ubuntu@52.89.123.45
   ```

### 🌆 Ending Your Work Day

1. **Request shutdown**:
   ```batch
   scripts/shutdown_server.bat
   ```

2. **What happens**:
   - System checks server status
   - Connects to server via SSH (default user: `ubuntu`)
   - Sends vote notifications to all logged-in users
   - Waits for team votes (5 minutes)
   - Makes democratic decision

3. **Possible outcomes**:

   **✅ Vote Passes (Majority YES)**:
   ```
   *** VOTE PASSED - STOPPING SERVER ***
   The team has approved the shutdown request.
   Server stop command sent!
   Cost savings: Server will stop charging once fully stopped
   ```

   **❌ Vote Fails (Majority NO or tie)**:
   ```
   *** VOTE FAILED - SERVER CONTINUES ***
   The team has decided to keep the server running.
   Server will continue running and charging.
   ```

## 🗳️ Voting Process

### Initiator Voting Behavior

- The initiator’s IP is used to start the voting session.
- The initiator is not automatically counted as a YES vote.
- If the initiator is also logged in to the server, they may cast a vote like any other user using `vote_shutdown yes|no`.

### For the Person Requesting Shutdown

1. Run `scripts/shutdown_server.bat`
2. Wait for the voting process to complete
3. Accept the team's decision

### For Team Members Who Receive Vote Notification

When you see this enhanced notification in your terminal:
```
🗳️ ============================================
🗳️  SERVER SHUTDOWN VOTE
🗳️ ============================================
🗳️ Initiated by: Alice
🗳️ Reason: Save AWS costs
🗳️ Time: 14:30 UTC
🗳️ 
🗳️ ⏰ You have 5 MINUTES to vote:
🗳️ 
🗳️ ✅ To AGREE to shutdown:
🗳️    vote_shutdown yes
🗳️ 
🗳️ ❌ To REJECT shutdown:
🗳️    vote_shutdown no
🗳️ 
🗳️ ⚠️  No vote = NO vote (server stays online)
🗳️ ============================================
```

**To vote YES** (agree to shutdown):
```bash
vote_shutdown yes
# or
./vote_shutdown.sh yes
```

**To vote NO** (reject shutdown):
```bash
vote_shutdown no
# or  
./vote_shutdown.sh no
```

**To check voting status**:
```bash
vote_shutdown status
```

**To abstain** (counts as NO):
- Simply don't vote within the 5-minute window

### Enhanced Voting Experience

**Real-time updates during voting:**
```
🗳️  VOTE UPDATE: Bob (203.0.113.20) voted ✅ YES (agree to shutdown)
🗳️  VOTE UPDATE: Carol (203.0.113.30) voted ❌ NO (reject shutdown)
```

**Final results notification:**
```
🗳️ ============================================
🗳️ 📊 FINAL VOTING RESULTS
🗳️ ============================================
🗳️ ✅ YES votes: 2
🗳️ ❌ NO votes: 2 (including 1 non-voters)
🗳️ ============================================
🗳️ 🛡️  VOTE FAILED: Server will continue running.
🗳️ 💰 Team decided to keep server online.
🗳️ ============================================
```

### Voting Examples

**Scenario 1: Everyone Agrees**
```
📊 FINAL VOTING RESULTS
✅ YES votes: 3
❌ NO votes: 0 (including 0 non-voters)
🏁 VOTE PASSED: Server will shutdown in 30 seconds!
💾 SAVE YOUR WORK NOW!
```

**Scenario 2: Split Decision**  
```
📊 FINAL VOTING RESULTS
✅ YES votes: 1  
❌ NO votes: 2 (including 1 non-voters)
🛡️ VOTE FAILED: Server will continue running.
💰 Team decided to keep server online.
```

## ⚙️ Enhanced Server Commands

### Server-Side Voting Commands

**For regular team members:**
```bash
# Cast your vote (from any directory if symlink created)
vote_shutdown yes    # Agree to shutdown
vote_shutdown no     # Reject shutdown

# Check current voting status
vote_shutdown status

# Get help and see all commands  
vote_shutdown help
```

**For system administration:**
```bash
# Comprehensive connection debugging
vote_shutdown debug

# Check if there's an active voting session
vote_shutdown status
```

### Advanced Server Management

**Manual voting simulation** (for testing):
```bash
# Simulate vote initiation (normally done by Windows client)
/home/ubuntu/vote_shutdown.sh initiate 203.0.113.10

# Check what users are connected
who
w

# View vote files during active voting
ls -la /tmp/shutdown_vote/
```

## ⚙️ Configuration Management

### View Current Configuration

```batch
scripts\view_config.bat
```

Shows:
- AWS settings (Instance ID, Region)
- Server connection details (IP, SSH key)
- Team IP mappings
- Current user settings
- Configuration file status

### Update Your Settings

1. **Edit `config.bat`**:
   ```batch
   notepad config.bat
   ```

2. **Common changes**:
   ```batch
   REM Change your name and IP
   set YOUR_NAME=YourActualName
   set YOUR_IP=%DEV1_IP%  # or DEV2_IP, DEV3_IP

   REM Update SSH key location
   set KEY_FILE=C:\Users\YourName\Downloads\your-new-key.pem

   REM Add team member IPs
   set DEV1_IP=203.0.113.10
   set DEV2_IP=203.0.113.20
   set DEV3_IP=203.0.113.30
   ```

3. **Verify changes**:
   ```batch
   scripts\view_config.bat
   ```

## 🧰 Common Operations

### Check Server Status Without Starting

```powershell
# PowerShell (recommended on Windows)
aws ec2 describe-instances --instance-ids i-1234567890abcdef0 --query "Reservations[0].Instances[0].State.Name" --output text
```

### Get Current Server IP

```powershell
aws ec2 describe-instances --instance-ids i-1234567890abcdef0 --query "Reservations[0].Instances[0].PublicIpAddress" --output text
```

### Force Stop Server (Emergency)

```powershell
aws ec2 stop-instances --instance-ids i-1234567890abcdef0
```

⚠️ Warning: Only use emergency stop in urgent situations. It bypasses the democratic process.

### Connect to Server Manually

```powershell
ssh -i "C:\path\to\your\key.pem" ubuntu@YOUR-SERVER-IP
```

## 💸 Understanding Costs

- Compute charges apply only while running
- EBS charges apply even when stopped

## 🚨 Troubleshooting Tips (Windows)

- Test SSH port reachability without telnet:
  ```powershell
  Test-NetConnection -ComputerName YOUR-SERVER-IP -Port 22
  ```
- If `BatchMode=yes` fails in shutdown, the key may be passphrase-protected. Use an unencrypted key for automation or an ssh-agent.

---

**Next: [Security Guide →](SECURITY.md)**