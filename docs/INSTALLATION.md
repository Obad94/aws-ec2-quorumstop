# Installation Guide

This guide will walk you through setting up AWS EC2 QuorumStop from scratch.

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] Windows 10/11 machine
- [ ] AWS account with EC2 access
- [ ] EC2 instance running (any size)
- [ ] Basic familiarity with command prompt
- [ ] Team members' public IP addresses

## 🧲 (Optional) Elastic IP for Stable Address

If you do NOT want the public IP to change every start/stop cycle, allocate and associate an Elastic IP. This avoids frequent config rewrites and DNS / allow‑list churn.

### Why Use an Elastic IP?
- Stable SSH endpoint (no need to distribute new IP daily)
- Firewall / corporate allow-lists stay valid
- Easier automation (scripts less often need to update SERVER_IP)
- Recommended if the instance is started/stopped multiple times per day

### Allocate an Elastic IP
```powershell
aws ec2 allocate-address --domain vpc
```
Output includes "AllocationId" (e.g. eipalloc-0123456789abcdef0) and "PublicIp".

### Associate Elastic IP with Your Instance
```powershell
aws ec2 associate-address ^
  --instance-id i-YOURINSTANCE ^
  --allocation-id eipalloc-0123456789abcdef0
```

### Verify Association
```powershell
aws ec2 describe-addresses --allocation-ids eipalloc-0123456789abcdef0 --query "Addresses[0].[PublicIp,InstanceId]" --output table
```

### Update Security Groups (if needed)
No change usually required—rules reference 0.0.0.0/0 or your client IPs, not the instance IP. But update any external tooling referencing the old ephemeral IP.

### Costs / Considerations
- Elastic IPs are free while associated with a running or stopped instance (one per instance) but AWS charges for unused (unassociated) Elastic IPs.
- Release it if you no longer need it:
```powershell
aws ec2 release-address --allocation-id eipalloc-0123456789abcdef0
```

---

## 🛠️ Step 1: Install AWS CLI

### Download and Install

1. Go to [AWS CLI Installation Page](https://aws.amazon.com/cli/)
2. Download "AWS CLI for Windows" (MSI installer)
3. Run the installer as administrator
4. Restart Command Prompt after installation

### Verify Installation

```batch
aws --version
```
Expected output: `aws-cli/2.x.x Python/3.x.x Windows/10 exe/AMD64`

## 🔐 Step 2: Configure AWS Credentials

### Get Your AWS Credentials

1. Log into AWS Console
2. Click your name (top right) → **Security Credentials**
3. Scroll to **Access Keys** section
4. Click **Create Access Key** → **Command Line Interface (CLI)**
5. Download the CSV file with your credentials

### Configure AWS CLI

```batch
aws configure
```

Enter the following when prompted:
```
AWS Access Key ID: AKIA.................... (from your CSV)
AWS Secret Access Key: ................................ (from your CSV)
Default region name: us-west-2 (or your EC2 instance region)
Default output format: json
```

### Test AWS Access

```batch
aws sts get-caller-identity
```

Expected output:
```json
{
    "UserId": "AIDA...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

## 🌐 Step 3: Configure EC2 Security Groups

### Required Inbound Rules

Your EC2 security group needs these rules:

| Type | Protocol | Port | Source | Description |
|------|----------|------|--------|-------------|
| SSH | TCP | 22 | YOUR_IP/32 | Your public IP |
| SSH | TCP | 22 | TEAMMATE_IP_1/32 | Teammate 1's IP |
| SSH | TCP | 22 | TEAMMATE_IP_2/32 | Teammate 2's IP |
| HTTP | TCP | 80 | 0.0.0.0/0 | Web traffic (optional) |
| HTTPS | TCP | 443 | 0.0.0.0/0 | Secure web (optional) |

### How to Add Rules

1. AWS Console → **EC2** → **Security Groups**
2. Find your instance's security group
3. Click **Edit inbound rules**
4. **Add rule** for each team member's IP
5. **Save rules**

### Find Your Public IP

Each team member should visit: [whatismyipaddress.com](https://whatismyipaddress.com)

## 🔑 Step 4: Set Up SSH Access

Default user in this project: `ubuntu` (Ubuntu AMIs). Some AMIs use `ec2-user` (Amazon Linux).

### Option A: Generate New SSH Key Pair

```batch
# Generate new key pair in AWS Console
# EC2 → Key Pairs → Create Key Pair
# Download the .pem file to your Downloads folder
```

### Option B: Convert Existing PuTTY Key

If you have a `.ppk` file:

1. Open **PuTTYgen**
2. Click **Load** → Select your `.ppk` file
3. **Conversions** → **Export OpenSSH key**
4. Save as `your-aws-key.pem` (no passphrase)

### Test SSH Connection

```powershell
ssh -i "C:\path\to\your-key.pem" ubuntu@YOUR-EC2-PUBLIC-IP
# If it fails, check port reachability:
Test-NetConnection -ComputerName YOUR-EC2-PUBLIC-IP -Port 22
```

## 📁 Step 5: Download and Configure Scripts

### Clone Repository

```batch
# Option 1: Git clone (if you have git)
git clone https://github.com/Obad94/aws-ec2-quorumstop.git
cd aws-ec2-quorumstop
```

### Configure Your Environment

1. **Run setup wizard (new)**:
   ```batch
   tools\setup-wizard.bat
   ```
   or manually edit below.

2. **Manual edit (legacy)** `scripts/config.bat`:
   ```batch
   notepad scripts\config.bat
   ```

3. **Find Your Instance ID**:
   ```batch
   aws ec2 describe-instances --query "Reservations[*].Instances[*].[InstanceId,Tags[?Key=='Name'].Value|[0],State.Name]" --output table
   ```

## 🧪 Step 6: Test Your Setup

### Test AWS Connectivity

```batch
scripts\test_aws.bat
```

Expected output:
```
=== AWS Debug Test ===
...
SUCCESS: All AWS commands working!
```

### Test Configuration

```batch
scripts\view_config.bat
```

### Test Server Start/Stop

```batch
scripts\start_server.bat
scripts\shutdown_server.bat
```

## 🏗️ Step 7: Server-Side Setup

### Install Enhanced Vote Script on EC2

SSH into your EC2 instance and set up the voting system:

```bash
# Connect to your server (from Windows PowerShell/Cmd, adjust path)
ssh -i "C:\path\to\your\key.pem" ubuntu@YOUR-SERVER-IP
```

### Method 1: Download from Repository

```bash
# Download the script directly
wget https://raw.githubusercontent.com/Obad94/aws-ec2-quorumstop/main/server/vote_shutdown.sh

# Or use curl if wget is not available
curl -o vote_shutdown.sh https://raw.githubusercontent.com/Obad94/aws-ec2-quorumstop/main/server/vote_shutdown.sh

# Make executable
chmod +x vote_shutdown.sh

# Move to home directory
mv vote_shutdown.sh /home/ubuntu/
```

### Method 2: Create Script Manually

```bash
# Create the script file
nano /home/ubuntu/vote_shutdown.sh

# Copy and paste the complete script content from server/vote_shutdown.sh
# Save and exit (Ctrl+X, Y, Enter)

# Make executable
chmod +x /home/ubuntu/vote_shutdown.sh
```

### Create System-Wide Command (Optional)

```bash
# Create symlink for easy access (requires sudo)
sudo ln -sf /home/ubuntu/vote_shutdown.sh /usr/local/bin/vote_shutdown

# Now users can run just "vote_shutdown" from anywhere
```

### Configure Your Team

Edit the script to add your team members:

```bash
# Edit the script
nano /home/ubuntu/vote_shutdown.sh

# Find this section and update with your team's real IP addresses and names:
declare -A DEV_NAMES
DEV_NAMES["YOUR_IP_1"]="YourName1"     # Replace with actual IP and name
DEV_NAMES["YOUR_IP_2"]="YourName2"     # Replace with actual IP and name  
DEV_NAMES["YOUR_IP_3"]="YourName3"     # Replace with actual IP and name
# Add more team members as needed

# Save and exit
```

### Test the Installation

```bash
# Test the script
./vote_shutdown.sh debug
```

**Expected output:**
```
=== 🔍 DEBUG INFORMATION ===

🌐 Network Connection Detection:
  SSH_CLIENT: 203.0.113.10 54892 22
  SSH_CONNECTION: 203.0.113.10 54892 172.31.1.100 22

📍 IP Detection Methods:
  ✅ SSH_CLIENT method: 203.0.113.10
  ✅ SSH_CONNECTION method: 203.0.113.10

👨‍👩‍👧‍👦 Team Member Mappings:
  203.0.113.10 → YourName1
  203.0.113.20 → YourName2

✅ Script is ready for democratic voting!
```

### Test Voting Commands

```bash
# Show help and usage
./vote_shutdown.sh help

# Check voting status
./vote_shutdown.sh status

# Test vote recording (will show error if no active vote)
./vote_shutdown.sh yes
```

## ✅ Step 8: Verification

### Complete System Test

1. **Start server** (if stopped):
   ```batch
   scripts\start_server.bat
   ```

2. **SSH into server** to simulate multiple users:
   ```powershell
   ssh -i "C:\path\to\your-key.pem" ubuntu@YOUR-SERVER-IP
   ```

3. **From another command prompt, test shutdown**:
   ```batch
   scripts\shutdown_server.bat
   ```

4. **Vote from the SSH session**:
   ```bash
   # In the SSH session, when prompted:
   vote_shutdown yes
   ```

If everything works, you should see the voting process complete successfully!

## 🎉 Installation Complete!

Your EC2 Democratic Shutdown System is now ready. Next steps:

1. **Share scripts with team members** - Each person needs their own copy with their IP configured
2. **Read the [Usage Guide](USAGE.md)** - Learn daily operations
3. **Review [Security Guide](SECURITY.md)** - Implement best practices
4. **Check [Troubleshooting](TROUBLESHOOTING.md)** - If you encounter issues

## 🆘 Need Help?

- Check our [Troubleshooting Guide](TROUBLESHOOTING.md)
- [Open an issue](https://github.com/Obad94/aws-ec2-quorumstop/issues)
- Review your configuration with `scripts\view_config.bat`

---

**Next: [Configuration Guide →](CONFIGURATION.md)**