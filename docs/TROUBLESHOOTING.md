# Troubleshooting Guide

Updated for unanimous voting rule, dynamic roster sync (team.map), and helper libraries.

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

## 🔄 Public IP Sync Issues

### Problem: `SERVER_IP` remains 0.0.0.0
- Instance not running yet → start then rerun `start_server.bat`.
- No public IP (private subnet without Elastic IP) → associate Elastic IP or enable public addressing.

### Problem: `SERVER_IP` not updated after start
Check presence of comment marker in `config.bat`:
```
REM Server Connection (Dynamic)
set SERVER_IP=...
```
`lib_update_config.bat` searches for that marker. If removed, restore from sample.

### Problem: IP resolves as "None"
Public IP not allocated yet. Script retries; if still None, wait 10–30s and rerun.

## 👥 Roster Sync Problems

### Problem: Names show as `Unknown(<ip>)` in vote output
Cause: `~/.quorumstop/team.map` missing or stale.
Fix:
```batch
scripts\sync_team.bat /debug   REM (omit /auto to see errors)
```
Confirm upload: On server:
```bash
ls -l ~/.quorumstop/team.map
cat ~/.quorumstop/team.map
```
Ensure lines: `IP Name` with no trailing carriage returns (script strips CR).

### Problem: New teammate not counted
- Added `DEVn_IP` / `DEVn_NAME` but forgot to increment `TEAM_COUNT`.
- Sync failed (SSH issue).
- Teammate not actually connected (no active `who` output entry) → only connected users must vote.

### Problem: Old teammate still appears
Remove / renumber dev entries and decrement `TEAM_COUNT`. Then initiate any shutdown (sync overwrites server map). Stale names vanish.

## 🗳️ Voting Issues

### Problem: Vote always fails even with everyone voting
Check for an extra idle / detached SSH session. On server:
```bash
who
```
All listed sessions count toward required unanimous YES (initiator auto-recorded). Anyone not casting a vote before timeout becomes an implicit NO.

### Problem: Need majority instead of unanimous
Modify logic in `vote_shutdown.sh` (final result block). Example majority snippet:
```bash
local needed=$(( total_participants/2 + 1 ))
if [[ $yes_votes -ge $needed ]]; then
  # PASS majority
else
  # FAIL
fi
```
Document change for team; update README references.

### Problem: Immediate PASS without waiting
Happens when initiator is only connected user (solo auto-pass feature). Open second SSH session to test full vote.

### Problem: Vote script not broadcasting
Check wall utility availability. On minimal images install `bsdmainutils` / `util-linux` depending on distro. Try `--plain` to fallback textual output.

## 📁 File / Permission Issues

### Problem: team.map uploads but unreadable
Set proper permissions:
```bash
chmod 700 ~/.quorumstop
```
Verify contents free of Windows CRLF (script already strips). If manual edits introduced CR: `tr -d '\r' < team.map > t && mv t team.map`.

### Problem: Vote log not created
Manually seed and set perms:
```bash
sudo touch /var/log/quorumstop-votes.log
sudo chown ubuntu:ubuntu /var/log/quorumstop-votes.log
sudo chmod 640 /var/log/quorumstop-votes.log
```
Run another vote test.

## 🧪 Helper Library Issues

### Problem: `lib_ec2.bat` returns exit code 2
Indicates AWS CLI error or empty query. Test raw describe:
```powershell
aws ec2 describe-instances --region %AWS_REGION% --instance-ids %INSTANCE_ID%
```
Fix region/instance mismatch.

### Problem: Capturing value into variable fails
Use `/value` (alias of `/quiet`) and FOR loop:
```batch
for /f %%S in ('call scripts\lib_ec2.bat :GET_STATE /value') do set CUR=%%S
```

## 🧾 Logging / Audit

### Missing lines
Check disk space: `df -h`. If rotated or truncated unexpectedly, investigate potential tampering.

### Correlating Stop Event
CloudTrail `StopInstances` timestamp should follow a `VOTE_RESULT PASS` log line. Absence suggests out-of-band manual stop; review IAM usage.

## 🧰 Windows Batch Pitfalls

### Paths with spaces
Quote KEY_FILE path in config: `set KEY_FILE=C:\Users\John Doe\Downloads\key.pem` works (batch tolerant), but safest: no spaces or wrap operations in quotes when used.

### Double-click runs then closes
Always launch from an existing terminal to view output; `/auto` removes pauses purposely.

## 🚀 Recovery Steps (Broken System)

1. Backup current `config.bat`.
2. Replace helper scripts from repo HEAD.
3. Recreate vote script on server (curl RAW).
4. Re-run `scripts\test_aws.bat`.
5. Start → vote test.

## 🚨 Emergency Manual Stop
```powershell
aws ec2 stop-instances --instance-ids %INSTANCE_ID%
```
Then inspect why voting path failed before reusing automation.

## ✅ Preventative Checklist

| Frequency | Action |
|-----------|--------|
| Weekly | Run `test_aws.bat`; prune idle SSH keys; review costs |
| Weekly | Confirm roster accuracy / TEAM_COUNT alignment |
| Monthly | Patch OS; update AWS CLI; verify log integrity |
| Quarterly | Review IAM least privilege & CloudTrail alerts |

---
If unresolved, open an Issue with: error text, `test_aws.bat` output snippet, and relevant log lines.