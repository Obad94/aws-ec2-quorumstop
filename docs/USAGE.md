# Usage Guide

This guide covers daily operations and common workflows with the EC2 Democratic Shutdown System.

## 🚀 Quick Reference

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `start_server.bat` | Start EC2 instance | Beginning of work day |
| `shutdown_server.bat` | Request team shutdown | End of work day |
| `view_config.bat` | Show configuration | Check settings/IP |
| `test_aws.bat` | Test AWS connectivity | Troubleshooting |

## 📅 Daily Workflow

### 🌅 Starting Your Work Day

1. **Start the server**:
   ```batch
   start_server.bat
   ```

2. **Expected output**:
   ```
   === EC2 Democratic Shutdown - Server Startup ===
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
   # The script shows you the SSH command:
   ssh -i "C:\Users\YourName\Downloads\your-key.pem" ubuntu@52.89.123.45
   ```

### 🌆 Ending Your Work Day

1. **Request shutdown**:
   ```batch
   shutdown_server.bat
   ```

2. **What happens**:
   - System checks server status
   - Connects to server via SSH
   - Sends vote notifications to all logged-in users
   - Waits for team votes (60 seconds)
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

### For the Person Requesting Shutdown

1. Run `shutdown_server.bat`
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
🎯 VOTE PASSED: Server will shutdown in 30 seconds!
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
./vote_shutdown.sh initiate 203.0.113.10

# Check what users are connected
who
w

# View vote files during active voting
ls -la /tmp/shutdown_vote/
```

## ⚙️ Configuration Management

### View Current Configuration

```batch
view_config.bat
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
   view_config.bat
   ```

## 🔧 Common Operations

### Check Server Status Without Starting

```batch
# Use AWS CLI directly
aws ec2 describe-instances --instance-ids i-1234567890abcdef0 --query "Reservations[0].Instances[0].State.Name" --output text
```

### Get Current Server IP

```batch
# Use AWS CLI directly  
aws ec2 describe-instances --instance-ids i-1234567890abcdef0 --query "Reservations[0].Instances[0].PublicIpAddress" --output text
```

### Force Stop Server (Emergency)

```batch
# Use AWS CLI directly (bypasses voting)
aws ec2 stop-instances --instance-ids i-1234567890abcdef0
```

**⚠️ Warning**: Only use emergency stop in urgent situations. It bypasses the democratic process.

### Connect to Server Manually

```batch
# Get the command from view_config.bat, or:
ssh -i "C:\path\to\your\key.pem" ubuntu@YOUR-SERVER-IP
```

## 📊 Understanding Costs

### When You're Charged

- ✅ **EC2 Compute**: Only when instance is running
- ✅ **EBS Storage**: Always (even when stopped) - ~$0.10/GB/month
- ✅ **Data Transfer**: Outbound internet traffic
- ❌ **Stopped Instance**: No compute charges

### Cost Examples

**t3.medium instance**:
- Running 24/7: ~$35/month
- Running 8 hours/day (work hours): ~$12/month
- Running only when needed: ~$5-15/month
- EBS storage (20GB): ~$2/month (always)

### Maximize Savings

1. **Use democratic shutdown** - Avoid leaving server running unnecessarily
2. **Coordinate with team** - Plan work hours to minimize overlapping usage
3. **Consider hibernation** - For faster startups (supported instance types only)

## 🚨 Troubleshooting Common Issues

### SSH Connection Fails

**Problem**: Cannot connect to server
```
ssh: connect to host 52.89.123.45 port 22: Connection refused
```

**Solutions**:
1. **Check server status**:
   ```batch
   start_server.bat  # This will show current status
   ```

2. **Verify IP is current**:
   ```batch
   view_config.bat  # Shows configured IP
   ```

3. **Check security group**:
   - AWS Console → EC2 → Security Groups
   - Ensure your IP has SSH (port 22) access

4. **Wait for server to fully boot**:
   - Server takes 30-60 seconds to become ready after "running" state

### Voting Doesn't Work

**Problem**: Vote script fails or times out

**Solutions**:
1. **Check SSH connectivity first**:
   ```batch
   ssh -i "C:\path\to\key.pem" ubuntu@SERVER-IP
   ```

2. **Verify vote script exists on server**:
   ```bash
   # On the server:
   ls -la /home/ubuntu/vote_shutdown.sh
   ./vote_shutdown.sh debug
   ```

3. **Re-install vote script**:
   - Follow Step 7 in [Installation Guide](INSTALLATION.md)

### AWS CLI Errors

**Problem**: AWS commands fail

**Solutions**:
1. **Test AWS CLI**:
   ```batch
   test_aws.bat
   ```

2. **Reconfigure credentials**:
   ```batch
   aws configure
   ```

3. **Check permissions**:
   - Your AWS user needs EC2 permissions
   - Minimum required: `ec2:DescribeInstances`, `ec2:StartInstances`, `ec2:StopInstances`

### Server Won't Start

**Problem**: `start_server.bat` fails

**Common causes**:
1. **Instance doesn't exist**: Check INSTANCE_ID in config.bat
2. **Wrong region**: Check AWS_REGION in config.bat  
3. **No permissions**: Your AWS user can't start instances
4. **Instance limit reached**: AWS account limits

**Debug steps**:
```batch
# Check if instance exists
aws ec2 describe-instances --instance-ids i-your-instance-id

# Check your permissions
aws iam get-user

# Check region
aws configure get region
```

## 🔄 Advanced Workflows

### Multi-Team Setup

If you have multiple teams using different servers:

1. **Create separate directories**:
   ```
   C:\ec2-scripts\team-frontend\
   C:\ec2-scripts\team-backend\
   C:\ec2-scripts\team-devops\
   ```

2. **Each directory has its own**:
   - `config.bat` (different INSTANCE_ID)
   - All script files
   - Team-specific settings

3. **Switch between teams**:
   ```batch
   cd C:\ec2-scripts\team-frontend\
   start_server.bat
   ```

### Scheduled Operations

**Auto-start at 9 AM (optional)**:
1. Use Windows Task Scheduler
2. Create task: Run `start_server.bat` at 9 AM weekdays
3. Configure: "Run whether user is logged on or not"

**Reminder shutdown at 6 PM**:
1. Create task: Display message at 6 PM
2. Message: "Consider running shutdown_server.bat to save costs"
3. Team decides whether to actually shut down

### Integration with Team Chat

**Slack notifications** (advanced):
1. Add webhook to vote script
2. Notify team channel when votes are requested
3. Share results in team chat

Example webhook addition to server script:
```bash
# Add to vote_shutdown.sh
curl -X POST -H 'Content-type: application/json' \
--data '{"text":"🗳️ Server shutdown vote requested. Check your terminal!"}' \
YOUR_SLACK_WEBHOOK_URL
```

## 📈 Monitoring and Analytics

### Track Usage Patterns

**Log voting results**:
```batch
# Add to shutdown_server.bat (after vote result)
echo %date% %time% - Vote by %YOUR_NAME% - Result: %VOTE_RESULT% >> shutdown_log.txt
```

**Analyze costs**:
- Check AWS Cost Explorer monthly
- Compare months with/without democratic shutdown
- Track which team members initiate most shutdowns

### Weekly Team Review

**Suggested agenda**:
1. Review shutdown log for the week
2. Discuss any failed votes (why?)
3. Adjust team agreements if needed
4. Check AWS costs vs. previous period

## 🤝 Team Agreements

### Recommended Team Policies

1. **Daily shutdown**: Team agrees to shut down by 7 PM unless actively working
2. **Weekend shutdown**: Always shut down Friday evening
3. **Emergency override**: Senior developer can force shutdown in cost emergencies
4. **Voting etiquette**: Respond to votes within 60 seconds when possible
5. **Work announcements**: Notify team before starting late/weekend work

### Sample Team Agreement

```
Our EC2 Democratic Shutdown Agreement:

✅ DO:
- Vote promptly when you see shutdown requests
- Announce if you'll be working late/weekends  
- Respect majority vote decisions
- Use start_server.bat at beginning of work day

❌ DON'T:
- Use emergency AWS console shutdown except in true emergencies
- Leave server running overnight without team agreement
- Ignore vote notifications
- Force shutdown during others' active work

🎯 GOALS:
- Save 50%+ on AWS costs
- Maintain team productivity  
- Build collaborative infrastructure habits
```

## 🆘 Getting Help

### Built-in Help

```batch
# Test your setup
test_aws.bat

# View current settings
view_config.bat

# Check if server is accessible
ssh -i "%KEY_FILE%" ubuntu@%SERVER_IP% "echo 'Connection test successful'"
```

### External Resources

- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [SSH Connection Troubleshooting](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/TroubleshootingInstancesConnecting.html)

### Community Support

- 🐛 [Report Issues](https://github.com/yourusername/ec2-democratic-shutdown/issues)
- 💬 [Ask Questions](https://github.com/yourusername/ec2-democratic-shutdown/discussions)
- 📚 [Check Wiki](https://github.com/yourusername/ec2-democratic-shutdown/wiki)

---

**Next: [Security Guide →](SECURITY.md)**