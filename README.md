# AWS EC2 QuorumStop

[//]: # (Status badges placeholder)
[![CI Status](https://img.shields.io/badge/CI-pending-lightgrey.svg)](../../actions)
[![Security Scan](https://img.shields.io/badge/Security-TBD-lightgrey.svg)](../../security)
[![Docs](https://img.shields.io/badge/Docs-Complete-brightgreen.svg)](docs/)

> A collaborative AWS EC2 management system that prevents accidental (or premature) shutdowns through a team vote, with automatic IP handling and audit logging.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Windows](https://img.shields.io/badge/Platform-Windows-blue.svg)](https://www.microsoft.com/windows)
[![AWS](https://img.shields.io/badge/Cloud-AWS-orange.svg)](https://aws.amazon.com/)

## 🎯 Problem Solved

**Scenario**: Your development team shares an AWS EC2 instance. Someone wants to shut it down to save costs, but others might still be working. How do you prevent disruptions while maintaining cost efficiency?

**Solution**: A democratic (unanimous‑by‑default) voting system where all connected users must agree before shutdown, with automatic safety checks, IP synchronization, and transparent logging.

## ✨ Key Features

- 🗳️ **Unanimous Voting (Default)**: All connected users must vote YES or the instance stays online (solo initiator auto‑passes)
- 🔄 **Dynamic Public IP Handling**: `start_server.bat` / `shutdown_server.bat` auto-resolve & persist changing EC2 IPs into `config.bat`
- 👥 **Config → team.map Sync**: Windows client generates and uploads `~/.quorumstop/team.map` (authoritative list) before votes
- 🧩 **Separation of Concerns**: Client batch scripts + minimal server shell script (`vote_shutdown.sh`)
- 📡 **AWS Helper Library**: `lib_ec2.bat` encapsulates state & public IP lookups (quiet/value modes for composition)
- ✍️ **Idempotent Config Rewriter**: `lib_update_config.bat` safely replaces only the `SERVER_IP` line (dedupes & marker based)
- 🚦 **/auto and /debug Modes**: Non-interactive automation or deep diagnostics (`start_server.bat /debug`, `shutdown_server.bat /auto`)
- 📊 **Transparent Output**: Structured console status, optional rich emoji UI server‑side (toggle with `--plain`)
- 📁 **Team Roster Variables**: `TEAM_COUNT`, `DEVn_IP`, `DEVn_NAME` drive generated map (no manual server edits needed)
- 🧪 **Connectivity Self-Test**: `test_aws.bat` validates CLI, identity, and EC2 describe permissions
- 🔐 **Safe Defaults**: Any missing vote or explicit NO blocks shutdown; root credential warnings surfaced
- 📝 **Audit Trail**: Server logs voting lifecycle to `/var/log/quorumstop-votes.log` (best‑effort permissions)

## 🚀 Quick Start

> New? First skim the [Installation Guide](docs/INSTALLATION.md) for AWS CLI setup, credentials, security group rules, and detailed step explanations, then return here for the condensed flow.

1. **Clone**
   ```bash
   git clone https://github.com/Obad94/aws-ec2-quorumstop.git
   cd aws-ec2-quorumstop
   ```
2. **Run Setup Wizard** (recommended – creates/updates `scripts\config.bat`):
   ```batch
   tools\setup-wizard.bat
   ```
   - Answer prompts (instance id, region, key path, team IPs/names, your identity).
   - Re-run anytime to add/change teammates.
   - (Manual copy/edit is deprecated; only use it if the wizard cannot run in your environment.)
3. **Test AWS Environment**
   ```batch
   scripts\test_aws.bat
   ```
4. **Start / Update Instance**
   ```batch
   scripts\start_server.bat
   ```
5. **Deploy / Update Server Vote Script** (after first start or when script changes)
   ```batch
   scripts\deploy_vote_script.bat /debug
   ```
   - Skips upload if hashes match (use `/force` to override)
   - Sets executable + symlink `/usr/local/bin/vote_shutdown`
6. **Initiate Shutdown Vote** (later when done working):
   ```batch
   scripts\shutdown_server.bat
   ```

## 📋 Prerequisites

- Windows 10/11
- AWS CLI v2 configured (least‑privilege IAM user/role: describe/start/stop EC2)
- One EC2 instance (Ubuntu recommended) accessible via SSH key
- Public IPs of teammates (static or current) for allow‑listing & mapping

## ⚙️ Configuration Overview

`config.bat` adds structured variables:
```
set TEAM_COUNT=3
set DEV1_IP=203.0.113.10
set DEV1_NAME=Alice
set DEV2_IP=203.0.113.20
set DEV2_NAME=Bob
set DEV3_IP=203.0.113.30
set DEV3_NAME=Carol
```
During `shutdown_server.bat`, a fresh `team.map` is built from these and uploaded. Server script loads it (overrides internal fallbacks) so you rarely need to edit `vote_shutdown.sh`.

## 🏗️ Architecture

```
Windows Batch Layer
  ├─ start_server.bat  (state + IP sync)
  ├─ shutdown_server.bat (vote initiation + AWS stop)
  ├─ sync_team.bat (team.map generation & upload)
  ├─ lib_ec2.bat / lib_update_config.bat (helpers)
  └─ config.bat (local, untracked)
        ↓ AWS CLI (state/IP)          
SSH (initiates vote) → vote_shutdown.sh (loads ~/.quorumstop/team.map) → vote dir / log → decision → aws ec2 stop-instances
```

### Decision Flow (Default Logic)
1. User runs `shutdown_server.bat`
2. Public IP revalidated & `config.bat` patched if changed
3. Team roster synced to server (`~/.quorumstop/team.map`)
4. Server auto-records initiator YES, broadcasts vote window (default 60s)
5. Each connected user votes (`vote_shutdown yes|no`)
6. REQUIREMENT: Unanimous YES of all connected users (non-vote counts as NO)
7. Solo initiator (no other SSH sessions) = auto PASS
8. On PASS → 30s grace → `stop-instances`; else abort

> Adjust unanimity by editing logic near the final result block in `server/vote_shutdown.sh`.

## 📚 Documentation

- [Installation Guide](docs/INSTALLATION.md)
- [Configuration Guide](docs/CONFIGURATION.md)
- [Usage Guide](docs/USAGE.md)
- [Security Guide](docs/SECURITY.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## 🎯 Use Cases

Ideal for shared dev / staging EC2 hosts where interactive work occurs sporadically and cost control matters. Not a production HA orchestration replacement.

## 💰 Cost Perspective (Illustrative)

| Runtime Pattern | Approx Uptime | Est. t3.medium Monthly |
|-----------------|---------------|------------------------|
| Always on       | 100%          | $35+                   |
| Voted Off Nights| ~50–60%       | $15–20                 |
| Aggressive Off  | ~30–40%       | $10–14                 |

## 📊 Voting Scenarios (Unanimous Rule)

| Connected Users | YES | NO | Non‑voters | Result            |
|-----------------|-----|----|-----------|-------------------|
| Alice           | 1   | 0  | 0         | PASS (solo)       |
| Alice,Bob       | 2   | 0  | 0         | PASS              |
| Alice,Bob       | 1   | 1  | 0         | FAIL              |
| A,B,C           | 3   | 0  | 0         | PASS              |
| A,B,C           | 2   | 0  | 1         | FAIL (missing)    |
| A,B,C           | 2   | 1  | 0         | FAIL (explicit NO) |

Rule: Any NO or any abstention (non-vote) causes failure.

## 🔒 Security Highlights

- No AWS secrets stored server-side
- Key-only SSH, strict least privilege recommended
- Root credential use visibly warned in `test_aws.bat`
- Voting artifacts cleaned after completion
- Log file restricted (640) where possible

## 🧪 Helper Scripts

| Script | Purpose |
|--------|---------|
| `scripts/start_server.bat` | Start instance, wait for state, sync IP | 
| `scripts/shutdown_server.bat` | Run vote then stop instance on pass |
| `scripts/deploy_vote_script.bat` | Upload/update `vote_shutdown.sh` (hash compare, symlink) |
| `scripts/lib_ec2.bat` | Query state/public IP (quiet/value modes) |
| `scripts/lib_update_config.bat` | Safe `SERVER_IP` rewrites |
| `scripts/sync_team.bat` | Generate & upload `team.map` |
| `scripts/test_aws.bat` | Environment & permission diagnostics |
| `scripts/view_config.bat` | Summarize active config |
| `tools/setup-wizard.bat` | Interactive generator/updater for `config.bat` |

Flags:
```
start_server.bat   [/auto] [/debug]
shutdown_server.bat [/auto] [/debug]
deploy_vote_script.bat [/debug] [/force]
vote_shutdown.sh   [--plain] yes|no|status|debug|help
tools\setup-wizard.bat [--auto] (env var driven)
```

## 🤝 Contributing

PRs welcome: clarify docs, add optional majority/supermajority mode examples, improve portability (PowerShell, Bash variants), unit test helpers.

## 📝 License

MIT – see `LICENSE`.

## 📞 Support

- Issues: https://github.com/Obad94/aws-ec2-quorumstop/issues
- Discussions: https://github.com/Obad94/aws-ec2-quorumstop/discussions

---

Quick Commands:
```batch
scripts\view_config.bat
scripts\start_server.bat
scripts\deploy_vote_script.bat /debug
scripts\shutdown_server.bat
scripts\test_aws.bat
```

Made with care for collaborative teams focused on cost & continuity.