# Server-Side Installation

This directory contains the server-side components for AWS EC2 QuorumStop.

## 📁 Files

- **`vote_shutdown.sh`** - Main voting script that handles team votes
- **`install.sh`** - Automated installation script  
- **`README.md`** - This file

## 🚀 Quick Installation

### Method 1: Automated Installation

```bash
# Download and run the installer
wget https://raw.githubusercontent.com/Obad94/aws-ec2-quorumstop/main/server/install.sh
chmod +x install.sh
./install.sh
```

### Method 2: Manual Installation

```bash
# Download the voting script
wget https://raw.githubusercontent.com/Obad94/aws-ec2-quorumstop/main/server/vote_shutdown.sh

# Make executable
chmod +x vote_shutdown.sh

# Move to home directory
mv vote_shutdown.sh /home/ubuntu/

# Create system-wide command (optional)
sudo ln -sf /home/ubuntu/vote_shutdown.sh /usr/local/bin/vote_shutdown
```

## 🔄 Dynamic Roster

Windows client builds & uploads `~/.quorumstop/team.map` at vote time. If present it overrides internal fallback names automatically—no regular manual edits required.

Validate roster:

```bash
cat ~/.quorumstop/team.map
```

Format: `IP Name` per line (comments prefixed with `#`).

## 🗳️ Voting Model (Default)

- UNANIMOUS yes of all currently connected SSH sessions (`who`) required.
- Initiator auto-recorded YES; solo initiator auto-pass.
- Timeout and grace: configurable at top of script (`VOTE_TIMEOUT`, `SHUTDOWN_DELAY`).
- Non-vote = NO (fail-safe).

To implement majority/supermajority, adjust the final decision block and update documentation.

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

## 📝 Logs

Audit log: `/var/log/quorumstop-votes.log`

Ensure permissions:

```bash
sudo touch /var/log/quorumstop-votes.log && \
  sudo chown ubuntu:ubuntu /var/log/quorumstop-votes.log && \
  sudo chmod 640 /var/log/quorumstop-votes.log
```

Tail recent entries:

```bash
tail -20 /var/log/quorumstop-votes.log
```

## 🔐 Permissions & Hardening

```bash
chmod 700 ~/.quorumstop 2>/dev/null || true
[ -d /tmp/shutdown_vote ] && chmod 700 /tmp/shutdown_vote 2>/dev/null || true
```

Consider CloudTrail alerts for out-of-band Start/Stop events lacking preceding PASS entries.

## ❓ Troubleshooting Quick Tips

| Issue | Check |
|-------|-------|
| Unknown(name) display | Was team.map uploaded? Permissions? CRLF? |
| Vote never passes | Extra idle SSH session holding unanimity hostage |
| Emojis garbled | Use `--plain` mode |
| Log missing | Permissions or path wrong |

Full guidance: see `../docs/` root documentation.

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