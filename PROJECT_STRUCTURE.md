# EC2 Democratic Shutdown - Complete Project Structure

Here's the complete directory structure for your open-source GitHub repository:

```
ec2-democratic-shutdown/
├── README.md                     # Main project documentation
├── LICENSE                       # MIT License
├── CONTRIBUTING.md              # Contribution guidelines
├── CHANGELOG.md                 # Version history
│
├── scripts/                     # Main batch scripts
│   ├── config.bat              # Configuration file
│   ├── start_server.bat        # Server startup script
│   ├── shutdown_server.bat     # Democratic shutdown script  
│   ├── view_config.bat         # Configuration viewer
│   └── test_aws.bat           # AWS connectivity test
│
├── server/                     # Server-side components
│   ├── vote_shutdown.sh        # Enhanced server-side voting script
│   ├── install.sh             # Server setup automation script
│   └── README.md              # Server installation instructions
│
├── docs/                       # Documentation
│   ├── INSTALLATION.md         # Installation guide
│   ├── CONFIGURATION.md        # Configuration guide
│   ├── USAGE.md               # Usage guide
│   ├── SECURITY.md            # Security best practices
│   └── TROUBLESHOOTING.md     # Troubleshooting guide
│
├── examples/                   # Example configurations
│   ├── team-3-developers/     # 3-person team setup
│   ├── team-5-developers/     # 5-person team setup
│   └── single-developer/      # Individual use
│
├── tools/                      # Utility tools
│   ├── setup-wizard.bat      # Initial setup wizard
│   ├── health-check.bat      # System health checker
│   └── cost-calculator.bat   # AWS cost estimator
│
└── .github/                   # GitHub-specific files
    ├── ISSUE_TEMPLATE/        # Issue templates
    ├── workflows/            # GitHub Actions (optional)
    └── PULL_REQUEST_TEMPLATE.md
```

## 📝 Additional Files to Create

### 1. LICENSE (MIT License)
```
MIT License

Copyright (c) 2024 EC2 Democratic Shutdown Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### 2. CONTRIBUTING.md
```markdown
# Contributing to EC2 Democratic Shutdown

Thank you for your interest in contributing! This project welcomes contributions from the community.

## How to Contribute

### 🐛 Report Bugs
1. Check existing [issues](https://github.com/yourusername/ec2-democratic-shutdown/issues)
2. Create detailed bug report with:
   - Steps to reproduce
   - Expected vs actual behavior
   - System information (Windows version, AWS CLI version)
   - Error messages (exact text)

### ✨ Suggest Features
1. Check [discussions](https://github.com/yourusername/ec2-democratic-shutdown/discussions)
2. Explain your use case and proposed solution
3. Consider backward compatibility

### 🔧 Submit Code Changes
1. Fork the repository
2. Create feature branch: `git checkout -b feature/your-feature-name`
3. Make changes and test thoroughly
4. Update documentation if needed
5. Submit pull request with clear description

## Development Guidelines

### Testing Your Changes
- Test with real AWS environment
- Test all voting scenarios
- Verify scripts work on different Windows versions
- Check error handling

### Code Style
- Follow existing batch script patterns
- Use clear variable names
- Add comments for complex logic
- Maintain consistent formatting

### Documentation
- Update relevant .md files
- Add examples for new features
- Keep README.md current
- Update CHANGELOG.md

## Getting Help

- 💬 [Discussions](https://github.com/yourusername/ec2-democratic-shutdown/discussions) for questions
- 📖 [Wiki](https://github.com/yourusername/ec2-democratic-shutdown/wiki) for detailed guides
```

### 3. CHANGELOG.md
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-MM-DD

### Added
- Initial release of EC2 Democratic Shutdown System
- Democratic voting system for server shutdowns
- Automatic IP management for dynamic EC2 instances
- Windows batch script interface
- Comprehensive documentation and guides
- AWS CLI integration
- SSH-based server communication
- Team configuration management

### Features
- Multi-user voting with configurable quorum
- Safety checks and grace periods
- Transparent voting results
- Cost optimization through collaborative shutdown
- Easy installation and setup process

## [Unreleased]

### Planned
- PowerShell version of scripts
- Slack/Teams integration for notifications
- Web-based voting interface
- Enhanced logging and analytics
- Support for multiple EC2 instances
```

### 4. Server-side Script (server/vote_shutdown.sh)
```bash
#!/bin/bash
# EC2 Democratic Shutdown - Server-side vote handler
# This script handles the voting logic on the EC2 instance

VOTE_DIR="/tmp/shutdown_vote"
VOTER_IP="$2"
ACTION="$1"

# Create vote directory
mkdir -p "$VOTE_DIR"

case "$ACTION" in
    "initiate")
        echo "=== DEMOCRATIC SHUTDOWN VOTE ==="
        echo "Vote initiated by IP: $VOTER_IP"
        echo "Sending notifications to all users..."
        
        # Clear old votes
        rm -f "$VOTE_DIR"/*
        
        # Send notification to all logged-in users
        wall "=== SERVER SHUTDOWN VOTE ===
Shutdown requested by $VOTER_IP
VOTE NOW within 60 seconds:
  echo yes > $VOTE_DIR/\$(whoami)_vote  # AGREE to shutdown
  echo no > $VOTE_DIR/\$(whoami)_vote   # REJECT shutdown
No vote = NO vote (default safe)"
        
        # Wait for votes
        echo "Waiting 60 seconds for votes..."
        sleep 60
        
        # Count votes
        yes_votes=0
        no_votes=0
        total_users=$(who | wc -l)
        
        echo "=== COUNTING VOTES ==="
        
        for vote_file in "$VOTE_DIR"/*_vote; do
            if [ -f "$vote_file" ]; then
                vote=$(cat "$vote_file" 2>/dev/null | tr -d '\n\r' | tr '[:upper:]' '[:lower:]')
                voter=$(basename "$vote_file" _vote)
                
                if [ "$vote" = "yes" ]; then
                    yes_votes=$((yes_votes + 1))
                    echo "✓ $voter: YES"
                elif [ "$vote" = "no" ]; then
                    no_votes=$((no_votes + 1))  
                    echo "✗ $voter: NO"
                fi
            fi
        done
        
        # Count non-voters as NO
        voted_count=$((yes_votes + no_votes))
        non_voters=$((total_users - voted_count))
        total_no=$((no_votes + non_voters))
        
        echo ""
        echo "=== RESULTS ==="
        echo "YES votes: $yes_votes"
        echo "NO votes: $no_votes (explicit)"
        echo "Non-voters: $non_voters (count as NO)"
        echo "Total NO: $total_no"
        echo "Required: Majority of $total_users users"
        
        # Decision logic: YES must be greater than total NO
        if [ "$yes_votes" -gt "$total_no" ]; then
            wall "*** VOTE PASSED ***
Shutdown approved by team vote!
Server will shutdown in 30 seconds.
Save your work NOW!"
            echo "VOTE PASSED - Shutdown approved"
            sleep 30
            exit 0  # Success - proceed with shutdown
        else
            wall "*** VOTE FAILED ***  
Team voted to keep server running.
Server will continue operating."
            echo "VOTE FAILED - Server continues running"
            exit 1  # Failure - do not shutdown
        fi
        ;;
    
    "debug")
        echo "=== DEBUG MODE ==="
        echo "Current users: $(who | wc -l)"
        echo "Logged in users:"
        who
        echo ""
        echo "Vote directory: $VOTE_DIR"
        if [ -d "$VOTE_DIR" ]; then
            echo "Vote files:"
            ls -la "$VOTE_DIR/" 2>/dev/null || echo "No vote files"
        fi
        echo "Script is ready for voting"
        exit 0
        ;;
        
    *)
        echo "Usage: $0 {initiate|debug} [voter_ip]"
        echo "  initiate voter_ip  - Start voting process"
        echo "  debug             - Show current status"
        exit 1
        ;;
esac
```

### 5. Example Team Configurations

**examples/team-3-developers/config.bat**:
```batch
@echo off
REM Example configuration for 3-developer team
set INSTANCE_ID=i-0123456789abcdef0
set AWS_REGION=us-west-2
set SERVER_IP=1.2.3.4
set KEY_FILE=C:\Users\%USERNAME%\Downloads\team-aws-key.pem

REM Team IP addresses
set ALICE_IP=203.0.113.10
set BOB_IP=203.0.113.20  
set CAROL_IP=203.0.113.30

REM Current user (each developer changes this)
set YOUR_NAME=Alice
set YOUR_IP=%ALICE_IP%

set SERVER_VOTE_SCRIPT=/home/ubuntu/vote_shutdown.sh
set SERVER_USER=ubuntu
```

### 6. Setup Wizard (tools/setup-wizard.bat)
```batch
@echo off
echo ========================================
echo    EC2 Democratic Shutdown Setup Wizard
echo ========================================
echo.
echo This wizard will help you configure the system.
echo.

REM Check prerequisites
echo [1/5] Checking prerequisites...
aws --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: AWS CLI not found!
    echo Please install AWS CLI first: https://aws.amazon.com/cli/
    pause
    exit /b 1
)
echo ✓ AWS CLI found

REM Get AWS credentials status
aws sts get-caller-identity >nul 2>&1
if errorlevel 1 (
    echo ERROR: AWS not configured!
    echo Please run: aws configure
    pause
    exit /b 1
)
echo ✓ AWS credentials configured

echo.
echo [2/5] Gathering your information...
set /p YOUR_NAME="Enter your name: "
set /p INSTANCE_ID="Enter your EC2 Instance ID (i-xxxxxxxxx): "
set /p AWS_REGION="Enter your AWS region (e.g., us-west-2): "
set /p KEY_FILE="Enter path to your SSH key (.pem file): "

echo.
echo [3/5] Getting your public IP...
echo Detecting your public IP address...
REM You could integrate with a service to get public IP
set /p YOUR_IP="Enter your public IP (check whatismyipaddress.com): "

echo.
echo [4/5] Team member IPs...
echo Enter IP addresses for your team members (optional):
set /p DEV1_IP="Developer 1 IP (press Enter to skip): "
if "%DEV1_IP%"=="" set DEV1_IP=0.0.0.0
set /p DEV2_IP="Developer 2 IP (press Enter to skip): "
if "%DEV2_IP%"=="" set DEV2_IP=0.0.0.0
set /p DEV3_IP="Developer 3 IP (press Enter to skip): "
if "%DEV3_IP%"=="" set DEV3_IP=0.0.0.0

echo.
echo [5/5] Creating configuration...

REM Create config.bat with user inputs
(
echo @echo off
echo REM ============================================
echo REM EC2 Democratic Shutdown - Configuration
echo REM Generated by Setup Wizard on %date% %time%
echo REM ============================================
echo.
echo REM AWS Configuration
echo set INSTANCE_ID=%INSTANCE_ID%
echo set AWS_REGION=%AWS_REGION%
echo.
echo REM Server Connection (Dynamic)
echo set SERVER_IP=1.2.3.4
echo set KEY_FILE=%KEY_FILE%
echo.
echo REM Team IP Mappings
echo set DEV1_IP=%DEV1_IP%
echo set DEV2_IP=%DEV2_IP%
echo set DEV3_IP=%DEV3_IP%
echo.
echo REM Current User Configuration
echo set YOUR_NAME=%YOUR_NAME%
echo set YOUR_IP=%YOUR_IP%
echo.
echo REM Server Configuration
echo set SERVER_VOTE_SCRIPT=/home/ubuntu/vote_shutdown.sh
echo set SERVER_USER=ubuntu
echo.
echo REM Display configuration when called with "show"
echo if "%%1"=="show" (
echo     echo ============================================
echo     echo EC2 Democratic Shutdown - Configuration
echo     echo ============================================
echo     echo.
echo     echo AWS Settings:
echo     echo   Instance ID: %%INSTANCE_ID%%
echo     echo   Region: %%AWS_REGION%%
echo     echo.
echo     echo Server Connection:
echo     echo   IP Address: %%SERVER_IP%%
echo     echo   SSH Key: %%KEY_FILE%%
echo     echo   User: %%SERVER_USER%%
echo     echo.
echo     echo Team IP Mappings:
echo     echo   Developer 1: %%DEV1_IP%%
echo     echo   Developer 2: %%DEV2_IP%%
echo     echo   Developer 3: %%DEV3_IP%%
echo     echo.
echo     echo Current User:
echo     echo   Name: %%YOUR_NAME%%
echo     echo   IP: %%YOUR_IP%%
echo     echo.
echo     echo Server Paths:
echo     echo   Vote Script: %%SERVER_VOTE_SCRIPT%%
echo     echo ============================================
echo )
) > config.bat

echo.
echo ✅ Setup completed successfully!
echo.
echo Created files:
echo   - config.bat (your configuration)
echo.
echo Next steps:
echo 1. Run: test_aws.bat (verify AWS connectivity)
echo 2. Run: start_server.bat (start your server)
echo 3. SSH to server and install vote_shutdown.sh (see docs/INSTALLATION.md)
echo 4. Run: shutdown_server.bat (test the voting system)
echo.
echo 📖 Read the documentation in the docs/ folder for detailed instructions.
echo.
pause
```

### 7. GitHub Issue Templates

**.github/ISSUE_TEMPLATE/bug_report.md**:
```markdown
---
name: Bug Report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''
---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Run command '...'
2. Enter configuration '....'
3. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Error message**
```
Paste the exact error message here
```

**System Information:**
- Windows version: [e.g. Windows 11]
- AWS CLI version: [run `aws --version`]
- Instance type: [e.g. t3.medium]
- AWS region: [e.g. us-west-2]

**Configuration (remove sensitive data)**
```batch
REM Your config.bat settings (remove IPs and keys)
set INSTANCE_ID=i-...
set AWS_REGION=...
```

**Additional context**
Add any other context about the problem here.
```

**.github/ISSUE_TEMPLATE/feature_request.md**:
```markdown
---
name: Feature Request
about: Suggest an idea for this project
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

**Is your feature request related to a problem? Please describe.**
A clear and concise description of what the problem is. Ex. I'm always frustrated when [...]

**Describe the solution you'd like**
A clear and concise description of what you want to happen.

**Describe alternatives you've considered**
A clear and concise description of any alternative solutions or features you've considered.

**Use case**
Describe your specific use case and how this feature would help.

**Additional context**
Add any other context or screenshots about the feature request here.
```

### 8. Security Best Practices (docs/SECURITY.md)
```markdown
# Security Guide

This guide covers security best practices for the EC2 Democratic Shutdown System.

## 🔒 Core Security Principles

### 1. SSH Key Management

**✅ Best Practices:**
- Generate unique SSH keys for each team member
- Use strong passphrases (but not for automation keys)
- Rotate keys regularly (every 6 months)
- Never share private keys via email/chat
- Store keys securely (encrypted storage)

**❌ Avoid:**
- Sharing the same SSH key among team members
- Storing keys in cloud storage without encryption
- Using weak or no passphrases
- Leaving keys on shared computers

### 2. AWS IAM Security

**Minimum Required Permissions:**
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

**Enhanced Security (Recommended):**
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
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "ec2:ResourceTag/Project": "YourProjectName"
                }
            }
        }
    ]
}
```

### 3. Network Security

**Security Group Configuration:**
- Only allow SSH (port 22) from team member IPs
- Use /32 CIDR blocks (single IP) not broader ranges
- Regularly audit and remove unused IP addresses
- Consider using a VPN for additional security

**Example Secure Rules:**
```
Type: SSH, Protocol: TCP, Port: 22, Source: 203.0.113.10/32 (Alice)
Type: SSH, Protocol: TCP, Port: 22, Source: 203.0.113.20/32 (Bob)
Type: SSH, Protocol: TCP, Port: 22, Source: 203.0.113.30/32 (Carol)
```

## 🛡️ Configuration Security

### Protecting Sensitive Information

**In config.bat:**
```batch
REM ✅ Good - No sensitive data exposed
set INSTANCE_ID=i-1234567890abcdef0
set AWS_REGION=us-west-2

REM ❌ Bad - Don't put credentials in files
REM set AWS_ACCESS_KEY=AKIA...
REM set AWS_SECRET_KEY=...
```

**Use AWS CLI credentials:**
```batch
REM Credentials stored securely by AWS CLI
aws configure set aws_access_key_id YOUR_KEY
aws configure set aws_secret_access_key YOUR_SECRET
```

### File Permissions

**Windows Security:**
- Right-click config.bat → Properties → Security
- Remove "Everyone" group if present
- Only allow specific users read/write access
- Consider encrypting the directory

## 🔍 Monitoring and Auditing

### AWS CloudTrail

Enable CloudTrail to log all API calls:
```json
{
    "eventSource": "ec2.amazonaws.com",
    "eventName": "StartInstances",
    "sourceIPAddress": "203.0.113.10",
    "userIdentity": {
        "userName": "alice"
    }
}
```

### Voting Audit Trail

**On the server, log votes:**
```bash
# Add to vote_shutdown.sh
echo "$(date): Vote by $VOTER_IP - $vote" >> /var/log/shutdown_votes.log
```

### Regular Security Reviews

**Monthly checklist:**
- [ ] Review AWS CloudTrail logs
- [ ] Check security group rules
- [ ] Audit team member access
- [ ] Verify SSH key rotation
- [ ] Review voting logs for anomalies

## 🚨 Incident Response

### Compromised SSH Key

1. **Immediate actions:**
   ```batch
   REM Remove compromised key from server
   ssh -i "backup-key.pem" ubuntu@server "sed -i '/compromised-key/d' ~/.ssh/authorized_keys"
   
   REM Update security group to block old IP
   aws ec2 revoke-security-group-ingress --group-id sg-12345678 --protocol tcp --port 22 --cidr 203.0.113.999/32
   ```

2. **Generate new keys:**
   ```batch
   REM Create new key pair
   aws ec2 create-key-pair --key-name new-team-key --query 'KeyMaterial' --output text > new-key.pem
   ```

3. **Update team configuration**

### Suspicious Activity

**Signs to watch for:**
- Unexpected server starts/stops
- Votes from unknown IPs
- Failed SSH attempts in logs
- Unusual AWS API calls

**Investigation steps:**
1. Check AWS CloudTrail logs
2. Review server access logs: `/var/log/auth.log`
3. Check voting logs
4. Verify all team members' recent activity

### Security Group Breach

**If security group is modified maliciously:**
```batch
REM Reset to known good state
aws ec2 authorize-security-group-ingress --group-id sg-12345678 --protocol tcp --port 22 --cidr 203.0.113.10/32
aws ec2 authorize-security-group-ingress --group-id sg-12345678 --protocol tcp --port 22 --cidr 203.0.113.20/32

REM Revoke suspicious rules
aws ec2 revoke-security-group-ingress --group-id sg-12345678 --protocol tcp --port 22 --cidr 0.0.0.0/0
```

## 🔐 Advanced Security Options

### AWS Systems Manager Session Manager

**Benefits:**
- No SSH keys required
- All sessions logged
- No inbound security group rules needed
- Centralized access control

**Setup:**
1. Install SSM agent on EC2 instance
2. Attach SSM role to instance
3. Use Session Manager instead of SSH

**Modified scripts to use SSM:**
```batch
REM Replace SSH commands with:
aws ssm start-session --target %INSTANCE_ID%
```

### Multi-Factor Authentication (MFA)

**For AWS CLI:**
```batch
REM Configure MFA device
aws configure set aws_mfa_device arn:aws:iam::123456789012:mfa/alice

REM Use temporary credentials
aws sts get-session-token --serial-number arn:aws:iam::123456789012:mfa/alice --token-code 123456
```

### VPN Access

**Setup VPN for team:**
1. Create AWS Client VPN endpoint
2. Configure client certificates
3. Update security groups to allow VPN CIDR
4. Team connects via VPN before using scripts

## 📋 Security Checklist

**Initial Setup:**
- [ ] Unique SSH keys for each team member
- [ ] Minimal IAM permissions configured
- [ ] Security groups restricted to team IPs only
- [ ] AWS CLI credentials properly configured
- [ ] CloudTrail enabled for auditing

**Ongoing Maintenance:**
- [ ] Monthly security group audit
- [ ] Quarterly SSH key rotation
- [ ] Regular review of AWS costs (detect unauthorized usage)
- [ ] Monitor voting patterns for anomalies
- [ ] Keep AWS CLI and tools updated

**Team Policies:**
- [ ] Document acceptable use policy
- [ ] Train team on security practices
- [ ] Establish incident response procedures
- [ ] Regular security awareness discussions

## 📞 Security Support

**If you discover a security vulnerability:**
1. Do not open a public GitHub issue
2. Email: security@[your-domain].com
3. Include: detailed description, steps to reproduce, potential impact
4. We will respond within 48 hours

**For security questions:**
- 📖 [Security Wiki](https://github.com/yourusername/ec2-democratic-shutdown/wiki/Security)
- 💬 [Private Security Discussion](https://github.com/yourusername/ec2-democratic-shutdown/discussions/categories/security)

---

Remember: Security is a team responsibility. Everyone should understand and follow these practices.
```

### 9. GitHub Actions Workflow (Optional)

**.github/workflows/test.yml**:
```yaml
name: Test Scripts

on:
  pull_request:
    branches: [ main ]
  push:
    branches: [ main ]

jobs:
  test-syntax:
    runs-on: windows-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Test Batch Script Syntax
      run: |
        # Basic syntax check for batch files
        Get-ChildItem -Path "scripts\*.bat" | ForEach-Object {
          Write-Host "Checking syntax: $($_.Name)"
          # Add basic syntax validation here
        }
      shell: powershell

  test-documentation:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Check Documentation Links
      run: |
        # Check for broken links in markdown files
        find docs -name "*.md" -exec echo "Checking {}" \;
```

---

## 🚀 Repository Setup Instructions

1. **Create GitHub repository:**
   ```bash
   # Create new repository on GitHub
   # Clone locally
   git clone https://github.com/yourusername/ec2-democratic-shutdown.git
   cd ec2-democratic-shutdown
   ```

2. **Create directory structure:**
   ```bash
   mkdir -p scripts server docs examples/{team-3-developers,team-5-developers,single-developer} tools .github/{ISSUE_TEMPLATE,workflows}
   ```

3. **Add all files:**
   - Copy all the artifacts I created into their respective directories
   - Add the additional files listed above
   - Customize with your GitHub username

4. **Initial commit:**
   ```bash
   git add .
   git commit -m "Initial release: EC2 Democratic Shutdown System v1.0.0"
   git push origin main
   ```

5. **Configure GitHub repository:**
   - Enable Issues and Discussions
   - Add repository description and topics
   - Set up branch protection rules
   - Configure GitHub Pages for documentation (optional)

6. **Add repository topics:**
   - `aws`
   - `ec2`
   - `cost-optimization`
   - `devops`
   - `windows`
   - `batch-scripts`
   - `team-collaboration`

This creates a comprehensive, professional open-source project that completely removes all your personal information while preserving the innovative democratic shutdown concept. The project is ready for community contributions and can help other teams solve similar collaborative infrastructure management challenges!