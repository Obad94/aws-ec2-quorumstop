# Installation Guide

Updated for dynamic team map syncing, unanimous voting default, and helper script enhancements.

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] Windows 10/11 workstation
- [ ] AWS CLI v2 installed
- [ ] IAM user/role with: ec2:DescribeInstances, ec2:StartInstances, ec2:StopInstances, sts:GetCallerIdentity
- [ ] EC2 instance (Ubuntu recommended) reachable via SSH (port 22)
- [ ] Teammates' public IP addresses (for security group + roster)
- [ ] SSH private key (.pem) locally

(Recommended) Elastic IP if frequent restarts cause IP churn and firewall pain points.

## 🧲 Elastic IP (Optional but Helpful)

Stable IP avoids repeated `SERVER_IP` rewrites. Steps (PowerShell):
```powershell
aws ec2 allocate-address --domain vpc
aws ec2 associate-address --instance-id i-YOURINSTANCE --allocation-id eipalloc-XXXXXXXXXXXX
```
Release later if unused:
```powershell
aws ec2 release-address --allocation-id eipalloc-XXXXXXXXXXXX
```

## 🛠️ Step 1: Install AWS CLI

Download MSI from https://aws.amazon.com/cli/ then verify:
```powershell
aws --version
```

## 🔐 Step 2: Configure AWS Credentials

```powershell
aws configure
```
Test:
```powershell
aws sts get-caller-identity
```

## 🌐 Step 3: Security Group Rules

Add inbound rules for each teammate's *current* public IP (SSH / TCP / 22 / x.x.x.x/32). Add any required app ports separately.

Find your IP: https://ifconfig.me (or similar site).

## 🔑 Step 4: SSH Key Prep

Ensure a non‑encrypted OpenSSH key (.pem). Test connectivity:
```powershell
ssh -i C:\path\to\key.pem ubuntu@EC2_PUBLIC_IP
```
If blocked:
```powershell
Test-NetConnection -ComputerName EC2_PUBLIC_IP -Port 22
```

## 📁 Step 5: Clone Repository

```powershell
git clone https://github.com/Obad94/aws-ec2-quorumstop.git
cd aws-ec2-quorumstop
```
(Or download ZIP & extract.)

## ⚙️ Step 6: Create Local Config

Copy sample then edit (never commit real one):
```powershell
copy scripts\config.sample.bat scripts\config.bat
notepad scripts\config.bat
```
Set at minimum:
```
INSTANCE_ID=...
AWS_REGION=...
KEY_FILE=...full path to .pem
SERVER_VOTE_SCRIPT=/home/ubuntu/vote_shutdown.sh
SERVER_USER=ubuntu
TEAM_COUNT=3
DEV1_IP=...  DEV1_NAME=Alice
DEV2_IP=...  DEV2_NAME=Bob
DEV3_IP=...  DEV3_NAME=Carol
YOUR_NAME=Alice
YOUR_IP=%DEV1_IP%
```
Leave `SERVER_IP=0.0.0.0` initially – startup/shutdown scripts will update it.

## 🧪 Step 7: Validate AWS Environment

```powershell
scripts\test_aws.bat
```
Expect SUCCESS section. Fix any credential / permission issues before proceeding.

## 🚀 Step 8: Start the Instance

```powershell
scripts\start_server.bat
```
On first run it will:
1. Detect current state.
2. Start if stopped.
3. Poll until running.
4. Resolve Public IP.
5. Persist new IP into `config.bat` via safe rewrite.

Use `/debug` for verbose trace, `/auto` for non-interactive (skip pauses):
```powershell
scripts\start_server.bat /debug
```

## 🏗️ Step 9: Install Server Vote Script

SSH into instance:
```powershell
ssh -i C:\path\to\key.pem ubuntu@<SERVER_IP>
```
Fetch script:
```bash
curl -o ~/vote_shutdown.sh https://raw.githubusercontent.com/Obad94/aws-ec2-quorumstop/main/server/vote_shutdown.sh
chmod +x ~/vote_shutdown.sh
sudo ln -sf /home/ubuntu/vote_shutdown.sh /usr/local/bin/vote_shutdown  # optional
```
No need to hardcode names inside the script—Windows client sync supplies a `team.map` each vote.

Test server script:
```bash
vote_shutdown help
vote_shutdown debug --plain
```

## 👥 Step 10: Prepare Team Roster Sync

Roster is auto-built when initiating a shutdown. You can test generation without actually voting:
```powershell
scripts\sync_team.bat
```
(Will upload `~/.quorumstop/team.map` if server reachable.)

File format on server (example):
```
# Auto-generated team map - Do NOT edit on server
203.0.113.10 Alice
203.0.113.20 Bob
203.0.113.30 Carol
```
Edits should happen only in `config.bat` then re-synced.

## 🗳️ Step 11: Trial Vote (Shutdown Flow)

Open 2–3 SSH sessions to simulate multiple users. From Windows:
```powershell
scripts\shutdown_server.bat /debug
```
Sequence:
1. Validates instance running & refreshes public IP if needed.
2. Generates / uploads `team.map`.
3. Initiates vote (initiator auto YES).
4. Server broadcasts instructions.
5. Users cast votes: `vote_shutdown yes|no`.
6. Unanimous pass → 30s grace → AWS stop command.

If solo (only initiator connected), shutdown proceeds immediately after short notice.

Use `/auto` for unattended automation (e.g., scheduled task) – it suppresses pauses.

## 🔍 Step 12: Verify Shutdown

After PASS observe:
```powershell
aws ec2 describe-instances --instance-ids <ID> --query "Reservations[0].Instances[0].State.Name" --output text
# -> stopping or stopped
```

## 🧼 Optional: Log & Directory Permissions

Ensure `/var/log/quorumstop-votes.log` gets created. If permission issues:
```bash
sudo touch /var/log/quorumstop-votes.log
sudo chown ubuntu:ubuntu /var/log/quorumstop-votes.log
sudo chmod 640 /var/log/quorumstop-votes.log
```

## 🛡️ IAM Least Privilege Example Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {"Effect": "Allow","Action": ["ec2:DescribeInstances"],"Resource": "*"},
    {"Effect": "Allow","Action": ["ec2:StartInstances","ec2:StopInstances"],"Resource": "arn:aws:ec2:REGION:ACCOUNT:instance/INSTANCE_ID"},
    {"Effect": "Allow","Action": ["sts:GetCallerIdentity"],"Resource": "*"}
  ]
}
```
Replace placeholders; optionally restrict region via condition.

## 🔁 Updating Components

- Pull repo updates: `git pull`.
- Re-fetch `vote_shutdown.sh` if server logic changed.
- Adjust timeouts / grace: edit top variables in server script.
- Change unanimity rule: modify result condition block.

## ⚡ Daily Usage Recap

Start day:
```powershell
scripts\start_server.bat
```
End day:
```powershell
scripts\shutdown_server.bat
```
Check config:
```powershell
scripts\view_config.bat
```
Connectivity test:
```powershell
scripts\test_aws.bat
```

## 🧪 Troubleshooting Pointers

| Symptom | Check |
|---------|-------|
| Cannot resolve state | AWS CLI configured? `aws sts get-caller-identity` |
| IP persists as 0.0.0.0 | Instance not running or no public IP yet; retry after a few seconds |
| Vote never passes | Another session abstaining? List users: `who` on server |
| SSH 255 error | Key path, permissions, security group ingress |
| team.map missing | Network/SSH failure during `sync_team.bat`; run with console verbosity (omit /auto) |

## ✅ Installation Complete

You now have:
- Dynamic IP persistence
- Unanimous shutdown voting with audit log
- Automatic roster syncing

Next steps:
- Refine IAM policy
- Consider Elastic IP or DNS alias
- Add scheduled task using `/auto` for nightly vote attempt or report

---

Continue to [Configuration Guide](CONFIGURATION.md) or [Usage Guide](USAGE.md).