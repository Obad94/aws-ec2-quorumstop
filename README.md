# EC2 Democratic Shutdown System

> A collaborative AWS EC2 management system that prevents accidental shutdowns through team voting and automated safety checks.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Windows](https://img.shields.io/badge/Platform-Windows-blue.svg)](https://www.microsoft.com/windows)
[![AWS](https://img.shields.io/badge/Cloud-AWS-orange.svg)](https://aws.amazon.com/)

## 🎯 Problem Solved

**Scenario**: Your development team shares an AWS EC2 instance. Someone wants to shut it down to save costs, but others might still be working. How do you prevent accidental disruptions while maintaining cost efficiency?

**Solution**: A democratic voting system where team members vote on server shutdowns, with automatic safety checks and transparent decision-making.

## ✨ Key Features

- 🗳️ **Democratic Voting**: Team members vote before any shutdown with real-time notifications
- 🛡️ **Safety Checks**: Automatic detection of active users and comprehensive connection analysis
- 🔄 **Dynamic IP Management**: Handles changing EC2 public IPs automatically
- 👥 **Multi-User Support**: Configurable for any team size with friendly name mapping
- 📊 **Transparent Results**: Rich formatted results with vote breakdown and decision logic
- ⚡ **Simple Interface**: Familiar Windows batch scripts with enhanced server-side voting
- 💰 **Cost Optimization**: Shutdown unused resources with team consensus and grace periods
- 🔧 **Self-Documenting**: Built-in help system and comprehensive debugging tools

## 🚀 Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/ec2-democratic-shutdown.git
   cd ec2-democratic-shutdown
   ```

2. **Configure your team settings**
   ```batch
   # Edit config.bat with your AWS details and team IPs
   notepad config.bat
   ```

3. **Start your server**
   ```batch
   start_server.bat
   ```

4. **Request shutdown (with team vote)**
   ```batch
   shutdown_server.bat
   ```

## 📋 Prerequisites

- Windows 10/11 (scripts are batch-based)
- [AWS CLI v2](https://aws.amazon.com/cli/) installed and configured
- AWS EC2 instance with proper IAM permissions
- SSH access to the EC2 instance
- Team members' public IP addresses

## 🏗️ Architecture

```
Windows Client Scripts → AWS CLI → EC2 Instance → SSH → Voting System → Decision
                     ↘           ↗
                       AWS APIs (Start/Stop)
```

### How It Works

1. **Start Process**: `start_server.bat` starts the EC2 instance and updates IP configuration
2. **Shutdown Request**: Any team member runs `shutdown_server.bat`
3. **Vote Notification**: System sends rich formatted notifications to all connected users via SSH
4. **Voting Period**: 5-minute window for team members to vote with real-time progress updates
5. **Decision**: Majority rules with transparent vote breakdown - ties default to "keep running" (safe choice)
6. **Action**: Server shuts down only with majority approval and 30-second grace period

## 📚 Documentation

- [📖 Installation Guide](docs/INSTALLATION.md) - Detailed setup instructions
- [⚙️ Configuration Guide](docs/CONFIGURATION.md) - Customize for your team
- [🔧 Usage Guide](docs/USAGE.md) - Daily operations and commands
- [🛡️ Security Guide](docs/SECURITY.md) - Best practices and security considerations
- [🐛 Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions

## 🎯 Use Cases

**Perfect For:**
- Development/staging environments
- Small to medium teams (3-10 developers)
- Shared resources with unpredictable usage patterns
- Cost-conscious teams wanting collaborative control

**Not Ideal For:**
- Production environments (use proper orchestration)
- Single-user instances (just use scheduled shutdown)
- Teams requiring 24/7 uptime

## 💰 Cost Savings

Typical savings for a `t3.medium` instance:
- **Without system**: $35/month (24/7 running)
- **With system**: $12-20/month (40-60% savings)
- **ROI**: Pays for itself immediately

## 📊 Example Voting Scenarios

| Scenario | YES | NO | Non-voters | Result |
|----------|-----|----|-----------| -------|
| All agree | 3 | 0 | 0 | ✅ SHUTDOWN |
| Split decision | 2 | 1 | 0 | ❌ STAY RUNNING |
| Partial votes | 1 | 1 | 1 | ❌ STAY RUNNING |
| No consensus | 1 | 0 | 2 | ❌ STAY RUNNING |

*Non-voters are counted as NO votes (safe default)*

## 🔒 Security Features

- Individual IP-based access control
- No hardcoded credentials in scripts
- SSH key-based authentication
- Audit trail of all voting decisions
- Safe defaults (no vote = no shutdown)

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Test with your AWS environment
4. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by the need for collaborative infrastructure management
- Built for teams who value both cost optimization and productivity
- Designed with safety and transparency as core principles

## 📞 Support

- 🐛 [Report Issues](https://github.com/yourusername/ec2-democratic-shutdown/issues)
- 💬 [Discussions](https://github.com/yourusername/ec2-democratic-shutdown/discussions)
- 📖 [Wiki](https://github.com/yourusername/ec2-democratic-shutdown/wiki)

---

**⚡ Quick Commands Reference:**

```batch
# View current configuration
view_config.bat

# Start server (updates IP automatically)
start_server.bat

# Request shutdown (initiates team vote)
shutdown_server.bat

# Test AWS connectivity
test_aws.bat

# Debug mode (comprehensive testing)
shutdown_server_debug.bat
```

**Made with ❤️ for collaborative teams**