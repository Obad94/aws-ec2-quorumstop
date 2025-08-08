# Server-Side Installation

This directory contains the server-side components for the EC2 Democratic Shutdown System.

## 📁 Files

- **`vote_shutdown.sh`** - Main voting script that handles team votes
- **`install.sh`** - Automated installation script  
- **`README.md`** - This file

## 🚀 Quick Installation

### Method 1: Automated Installation

```bash
# Download and run the installer
wget https://raw.githubusercontent.com/yourusername/ec2-democratic-shutdown/main/server/install.sh
chmod +x install.sh
./install.sh
```

### Method 2: Manual Installation

```bash
# Download the voting script
wget https://raw.githubusercontent.com/yourusername/ec2-democratic-shutdown/main/server/vote_shutdown.sh

# Make executable
chmod +x vote_shutdown.sh

# Move to home directory
mv vote_shutdown.sh /home/ubuntu/

# Create system-wide command (optional)
sudo ln -sf /home/ubuntu/vote_shutdown.sh /usr/local/bin/vote_shutdown
```

## ⚙️ Configuration

Edit the script to add your team members:

```bash
nano /home/ubuntu/vote_shutdown.sh

# Find and update this section:
declare -A DEV_NAMES
DEV_NAMES["YOUR_IP_1"]="YourName1"
DEV_NAMES["YOUR_IP_2"]="YourName2"  
DEV_NAMES["YOUR_IP_3"]="YourName3"
```

## 🧪 Testing

```bash
# Test installation
./vote_shutdown.sh debug

# Show help
./vote_shutdown.sh help

# Check voting status
./vote_shutdown.sh status
```

## 📖 Usage

**For team members:**
```bash
vote_shutdown yes    # Agree to shutdown
vote_shutdown no     # Reject shutdown
vote_shutdown status # Check current vote
```

**For administration:**
```bash
vote_shutdown debug  # Connection diagnostics
vote_shutdown help   # Show all commands
```

## 🔧 Troubleshooting

**Script not found:**
```bash
ls -la /home/ubuntu/vote_shutdown.sh
chmod +x /home/ubuntu/vote_shutdown.sh
```

**Team names show as "Unknown":**
```bash
# Edit script and update DEV_NAMES array with real IPs
nano /home/ubuntu/vote_shutdown.sh
```

**Voting notifications not appearing:**
```bash
# Check if wall command works
wall "Test message"
```

## 🔒 Security Notes

- Script runs with user permissions (no sudo required)
- Vote files stored in `/tmp/shutdown_vote/` (auto-cleaned)
- No persistent storage of sensitive data
- IP detection uses SSH environment variables

For complete documentation, see the main project README and docs folder.