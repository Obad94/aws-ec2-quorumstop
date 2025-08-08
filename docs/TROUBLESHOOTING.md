# Troubleshooting Guide

This guide helps you diagnose and fix common issues with AWS EC2 QuorumStop.

## 🔎 Quick Diagnosis

Run through these steps first to identify the problem category:

### 1. Basic System Check

```batch
REM Test AWS connectivity
scripts\test_aws.bat

REM View current configuration
scripts\view_config.bat

REM Check if config file exists and is readable
dir scripts\config.bat
```

### 2. Identify Problem Category

| Symptom | Likely Issue | Jump To |
|---------|-------------|---------|
| "AWS CLI not found" | Installation problem | [AWS CLI Issues](#aws-cli-issues) |
| "Cannot check server status" | Credentials/permissions | [AWS Authentication](#aws-authentication) |
| "SSH connection failed" | Network/security groups | [SSH Connection Problems](#ssh-connection-problems) |
| "Vote script failed" | Server-side setup | [Voting System Issues](#voting-system-issues) |
| Scripts won't run | Windows/path issues | [Windows Script Issues](#windows-script-issues) |

---

## 🛠️ AWS CLI Issues

### Problem: "AWS CLI not found" or "'aws' is not recognized"

**Cause**: AWS CLI not installed or not in system PATH

**Solution**:
1. **Download and install AWS CLI**:
   - Go to: https://aws.amazon.com/cli/
   - Download "AWS CLI for Windows" MSI installer
   - Run as administrator

2. **Restart Command Prompt**:
   ```batch
   # Close all Command Prompt windows
   # Open new Command Prompt
   aws --version
   ```

3. **If still not working, check PATH**:
   ```batch
   # Check if AWS CLI is in PATH
   echo %PATH%
   
   # Manually add AWS CLI to PATH (if needed)
   set PATH=%PATH%;C:\Program Files\Amazon\AWSCLIV2
   ```

### Problem: AWS CLI version conflicts

**Symptoms**: Old version reported, commands behave strangely

**Solution**:
```batch
# Uninstall old version first
# Then install AWS CLI v2 from official site

# Verify clean installation
aws --version
# Should show: aws-cli/2.x.x
```

---

## 🔐 AWS Authentication

### Problem: "Unable to locate credentials"

**Solution**:
```batch
# Configure AWS CLI
aws configure

# Enter when prompted:
# AWS Access Key ID: AKIA................
# AWS Secret Access Key: ........................................
# Default region name: us-west-2
# Default output format: json
```

### Problem: "An error occurred (UnauthorizedOperation)"

**Cause**: Your AWS user lacks necessary permissions

**Required permissions**:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:StartInstances", 
                "ec2:StopInstances"
            ],
            "Resource": "*"
        }
    ]
}
```

**Solution**:
1. Contact your AWS administrator
2. Or attach `AmazonEC2FullAccess` policy (broader permissions)

### Problem: "InvalidInstanceID.NotFound"

**Cause**: Wrong Instance ID in config.bat

**Solution**:
```batch
# List all your instances
aws ec2 describe-instances --query "Reservations[*].Instances[*].[InstanceId,Tags[?Key=='Name'].Value|[0],State.Name]" --output table

# Update config.bat with correct Instance ID
notepad config.bat
```

### Problem: "This region does not exist"

**Solution**:
```batch
# List available regions
aws ec2 describe-regions --query "Regions[*].RegionName" --output table

# Update config.bat with correct region
# Common regions: us-west-2, us-east-1, eu-west-1
```

---

## 🌐 SSH Connection Problems

### Problem: "Connection refused" or "Connection timed out"

**Diagnosis steps**:

1. **Check server status**:
   ```powershell
   aws ec2 describe-instances --instance-ids i-your-instance-id --query "Reservations[0].Instances[0].State.Name" --output text
   ```
   - Should show "running", not "stopped" or "pending"

2. **Verify IP address**:
   ```batch
   scripts\view_config.bat
   # Check if SERVER_IP matches actual public IP
   ```

3. **Test connectivity (PowerShell)**:
   ```powershell
   Test-NetConnection -ComputerName YOUR-SERVER-IP -Port 22
   ```

**Common solutions**:

### Solution 1: Security Group Issues

**Check inbound rules**:
1. AWS Console → EC2 → Security Groups
2. Find your instance's security group
3. Check inbound rules for SSH (port 22)
4. Ensure your IP address is allowed

**Fix security group**:
```
Type: SSH
Protocol: TCP
Port range: 22
Source: YOUR.PUBLIC.IP/32
```

**Get your current IP**:
- Visit: https://whatismyipaddress.com
- Compare with config.bat setting

### Solution 2: SSH Key Problems

**Test SSH key**:
```powershell
# Try connecting with verbose output
ssh -v -i "C:\path\to\your\key.pem" ubuntu@YOUR-SERVER-IP
```

**Common key issues**:
```bash
# Wrong permissions (if using WSL/Git Bash)
chmod 600 /path/to/your/key.pem

# Wrong key format
# Use PuTTYgen to convert .ppk to .pem if needed

# Wrong user
# Default in this project: ubuntu (Ubuntu AMIs)
# Some AMIs use 'ec2-user' (Amazon Linux)
ssh -i "key.pem" ec2-user@YOUR-SERVER-IP
```

### Solution 3: Server Still Booting

**Wait for full boot**:
- Server shows "running" but SSH not ready yet
- Wait 2-3 minutes after "running" state
- Check system log in AWS Console

---

## 🗳️ Voting System Issues

### Problem: "Vote script failed" or voting hangs

**Check server-side script installation:**
```bash
# SSH into server first
ssh -i "your-key.pem" ubuntu@YOUR-SERVER-IP

# Check if enhanced vote script exists
ls -la /home/ubuntu/vote_shutdown.sh

# Test enhanced vote script
./vote_shutdown.sh debug
```

**Expected enhanced debug output:**
```
=== 🔍 DEBUG INFORMATION ===

🌐 Network Connection Detection:
  SSH_CLIENT: 203.0.113.10 54892 22
  SSH_CONNECTION: 203.0.113.10 54892 172.31.1.100 22

📍 IP Detection Methods:
  ✅ SSH_CLIENT method: 203.0.113.10
  ✅ SSH_CONNECTION method: 203.0.113.10

👨‍👩‍👧‍👦 Team Member Mappings:
  203.0.113.10 → Alice
  203.0.113.20 → Bob

✅ Script is ready for democratic voting!
```

**If script is missing or outdated:**
```bash
# Download the latest enhanced script
wget https://raw.githubusercontent.com/Obad94/aws-ec2-quorumstop/main/server/vote_shutdown.sh

# Or recreate manually (see Installation Guide Step 7)
nano /home/ubuntu/vote_shutdown.sh
# Copy complete enhanced script content

# Make executable
chmod +x /home/ubuntu/vote_shutdown.sh

# Configure your team IPs
nano /home/ubuntu/vote_shutdown.sh
# Edit the DEV_NAMES array with your team's actual IPs and names
```

### Problem: Votes not counted correctly or team names show as "Unknown"

**Check team configuration:**
```bash
# View current team mapping
./vote_shutdown.sh debug | grep "Team Member Mappings" -A 10

# Should show your actual team members:
# 203.0.113.10 → Alice  
# 203.0.113.20 → Bob
# Not: Unknown(203.0.113.10)
```

**Fix team mapping:**
```bash
# Edit the script
nano /home/ubuntu/vote_shutdown.sh

# Find and update this section with your real IPs:
declare -A DEV_NAMES
DEV_NAMES["YOUR_REAL_IP_1"]="ActualName1"
DEV_NAMES["YOUR_REAL_IP_2"]="ActualName2"
DEV_NAMES["YOUR_REAL_IP_3"]="ActualName3"

# Save and test
./vote_shutdown.sh debug
```

### Problem: Enhanced voting features not working

**Symptoms**: No emojis, basic messages instead of rich formatting

**Solution**:
```bash
# Check script version by looking for enhanced features
grep "🗳️" /home/ubuntu/vote_shutdown.sh

# If not found, update to enhanced version
wget -O /home/ubuntu/vote_shutdown.sh https://raw.githubusercontent.com/Obad94/aws-ec2-quorumstop/main/server/vote_shutdown.sh

# Make executable and configure team
chmod +x /home/ubuntu/vote_shutdown.sh
nano /home/ubuntu/vote_shutdown.sh  # Update DEV_NAMES array
```

### Problem: "vote_shutdown: command not found"

**Cause**: System-wide symlink not created

**Solution**:
```bash
# Create symlink for easier access
sudo ln -sf /home/ubuntu/vote_shutdown.sh /usr/local/bin/vote_shutdown

# Test
vote_shutdown help

# Alternative: use full path
./vote_shutdown.sh help
```

### Problem: SSH connection works but voting fails

**Check BatchMode SSH**:
```powershell
# Test batch mode SSH (used by voting)
ssh -o BatchMode=yes -i "your-key.pem" ubuntu@SERVER-IP "echo 'Batch mode test'"
```

**If batch mode fails**:
- SSH key might require passphrase (not supported in batch mode)
- Generate new key without passphrase for automation, or use ssh-agent

---

## 💻 Windows Script Issues

### Problem: "The system cannot find the file specified"

**Check file locations**:
```batch
# Ensure all scripts are in same directory
dir *.bat

# Should see:
# config.bat
# start_server.bat  
# shutdown_server.bat
# view_config.bat
# test_aws.bat
```

### Problem: "Access is denied" or scripts won't run

**Solution**:
```batch
# Run Command Prompt as Administrator
# Right-click Command Prompt → "Run as administrator"

# Or check if files are blocked
# Right-click each .bat file → Properties → Unblock (if present)
```

### Problem: Scripts run but immediately close

**Cause**: Double-clicking .bat files

**Solution**: 
- Always run from Command Prompt or PowerShell
- Or add `pause` command at end of scripts

### Problem: "The filename, directory name, or volume label syntax is incorrect"

**Cause**: Paths with spaces not properly quoted

**Check config.bat**:
```batch
# Ensure paths with spaces are quoted
set KEY_FILE="C:\Users\Your Name\Downloads\key.pem"
# Not: C:\Users\Your Name\Downloads\key.pem
```

---

## 🔄 Server State Issues

### Problem: Server stuck in "pending" state

**Causes and solutions**:

1. **First boot taking long**: Wait up to 5 minutes
2. **Instance limits**: Check AWS account limits
3. **Insufficient capacity**: Try different instance type/AZ

```batch
# Check current state
aws ec2 describe-instances --instance-ids i-your-id --query "Reservations[0].Instances[0].State"

# If stuck, terminate and launch new instance (data loss!)
aws ec2 terminate-instances --instance-ids i-your-id
```

### Problem: Server stuck in "stopping" state

**Solution**:
```batch
# Force stop (may take up to 10 minutes)
aws ec2 stop-instances --instance-ids i-your-id --force

# If still stuck after 10 minutes, contact AWS support
```

### Problem: Server starts but gets different IP every time

**Solution**: Use Elastic IP
```batch
# Allocate Elastic IP
aws ec2 allocate-address --domain vpc

# Associate with instance
aws ec2 associate-address --instance-id i-your-id --allocation-id eipalloc-12345678
```

---

## 🚨 Emergency Procedures

### Emergency Server Stop (Bypass Voting)

```batch
# Direct AWS stop command
aws ec2 stop-instances --instance-ids i-your-instance-id

# Monitor until stopped
aws ec2 describe-instances --instance-ids i-your-instance-id --query "Reservations[0].Instances[0].State.Name"
```

**Use only when**:
- AWS costs are critical
- Voting system is broken
- Server is compromised
- Team consensus offline

### Reset Everything

**If system is completely broken**:

1. **Backup current config**:
   ```batch
   copy scripts\config.bat scripts\config_backup.bat
   ```

2. **Download fresh scripts** from GitHub

3. **Reconfigure**:
   ```batch
   notepad scripts\config.bat
   # Update with your settings from backup
   ```

4. **Test step by step**:
   ```batch
   scripts\test_aws.bat
   scripts\view_config.bat  
   scripts\start_server.bat
   ```

### Contact Support

**Before contacting support, gather**:
```batch
# System information
aws --version
echo %AWS_REGION%
echo %INSTANCE_ID%

# Error messages
# Copy exact error text from Command Prompt

# Configuration
scripts\view_config.bat

# AWS account info
aws sts get-caller-identity
```

**Where to get help**:
- 📖 Project Wiki (if enabled): https://github.com/Obad94/aws-ec2-quorumstop/wiki
- 🐛 Issues: https://github.com/Obad94/aws-ec2-quorumstop/issues
- 💬 Discussions: https://github.com/Obad94/aws-ec2-quorumstop/discussions

---

## ✅ Prevention Checklist

**Weekly maintenance**:
- [ ] Test `scripts\test_aws.bat` - ensure AWS connectivity
- [ ] Check security groups - verify team IP addresses
- [ ] Review AWS costs - confirm savings are realized
- [ ] Update SSH keys - rotate if needed
- [ ] Test voting system - ensure server script works

**Monthly maintenance**:
- [ ] Update AWS CLI if new version available  
- [ ] Review team IP changes (people working from different locations)
- [ ] Check instance health in AWS Console
- [ ] Backup configuration files
- [ ] Review and update team agreements

**When problems occur**:
1. ✋ **Don't panic** - most issues are configuration problems
2. 📝 **Document the error** - copy exact messages
3. 🔍 **Start with basics** - run `scripts\test_aws.bat`
4. 📖 **Check this guide** - search for your error message
5. 💬 **Ask for help** - provide full error details when asking

---

**Next: [Security Guide →](SECURITY.md)**