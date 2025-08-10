# Configuration Guide

This guide describes every configurable aspect of AWS EC2 QuorumStop after the refactor introducing dynamic team roster syncing and helper libraries.

## 🔧 Configuration Surfaces

1. Windows client (`scripts/`):
   - `config.bat` (authoritative local settings – NOT committed)
   - Helper libraries: `lib_ec2.bat`, `lib_update_config.bat`
2. EC2 server (`server/`):
   - `vote_shutdown.sh` (loads dynamic `~/.quorumstop/team.map` if present; fallbacks inside are only a safety net)

## 💻 Client Configuration (`scripts/config.bat`)

Minimum required variables (example):
```batch
REM AWS
set INSTANCE_ID=i-0123456789abcdef0
set AWS_REGION=us-west-2

REM Dynamic Public IP (auto-replaced by scripts/start_server.bat & shutdown_server.bat)
set SERVER_IP=0.0.0.0
set KEY_FILE=C:\Users\%USERNAME%\Downloads\mykey.pem
set SERVER_USER=ubuntu
set SERVER_VOTE_SCRIPT=/home/ubuntu/vote_shutdown.sh

REM Team Roster
set TEAM_COUNT=3
set DEV1_IP=203.0.113.10
set DEV1_NAME=Alice
set DEV2_IP=203.0.113.20
set DEV2_NAME=Bob
set DEV3_IP=203.0.113.30
set DEV3_NAME=Carol

REM Current User
set YOUR_NAME=Alice
set YOUR_IP=%DEV1_IP%
```

### Roster Rules
- `TEAM_COUNT` must equal the highest sequential `DEVn_` pair you define.
- Each dev entry is two variables: `DEVn_IP` and `DEVn_NAME` (NAME optional; if omitted, scripts fallback to DevN during local displays; server map requires name to appear in list).
- IPs can be updated per developer if ISP changes – just keep the mapping current or consider static/VPN endpoints.

### Adding / Removing Members
Increase or decrease `TEAM_COUNT` and add/remove the corresponding `DEVn_IP` / `DEVn_NAME` pairs. Old higher-numbered entries beyond `TEAM_COUNT` are ignored.

### Typical Small Team (3)
```batch
set TEAM_COUNT=3
set DEV1_IP=198.51.100.11 & set DEV1_NAME=Lead
set DEV2_IP=198.51.100.12 & set DEV2_NAME=Backend
set DEV3_IP=198.51.100.13 & set DEV3_NAME=Frontend
```

### Larger Team (6)
```batch
set TEAM_COUNT=6
set DEV1_IP=203.0.113.10 & set DEV1_NAME=Alice
set DEV2_IP=203.0.113.20 & set DEV2_NAME=Bob
set DEV3_IP=203.0.113.30 & set DEV3_NAME=Carol
set DEV4_IP=203.0.113.40 & set DEV4_NAME=Dave
set DEV5_IP=203.0.113.50 & set DEV5_NAME=Eve
set DEV6_IP=203.0.113.60 & set DEV6_NAME=Frank
```

### Personalization per Developer
Each teammate sets only their identity lines:
```batch
set YOUR_NAME=Bob
set YOUR_IP=%DEV2_IP%
```

### Never Commit Real Config
Use `config.sample.bat` in git; keep `config.bat` ignored. If accidentally committed, rotate any compromised key or instance values immediately.

## 🔄 Dynamic Public IP Persistence

`start_server.bat` and `shutdown_server.bat` will:
1. Query current public IP via `lib_ec2.bat :GET_PUBLIC_IP`.
2. Compare with `SERVER_IP` in `config.bat`.
3. If different (and non-empty / not "None" / not placeholder), rewrite only the `SERVER_IP=` line using `lib_update_config.bat` (marker anchored at comment: `Server Connection (Dynamic)`).

If you adopt an Elastic IP, the IP will simply stop changing and rewrites become no-ops.

## 👥 Team Map Sync (`sync_team.bat`)

Generated each shutdown vote attempt (and can be run manually) to produce `team.map` with lines:
```
<IP> <Name>
```
Uploaded to `~/.quorumstop/team.map` over SSH. The server script clears its internal `DEV_NAMES` and loads this file (CR stripped) – meaning server fallback list is only used if no map file arrives.

## 🗳️ Voting Logic (Defaults)

`vote_shutdown.sh` enforces UNANIMOUS consent of all currently connected SSH users (detected via `who`). Behavior specifics:
- Initiator auto-recorded as YES.
- Any explicit NO or non-vote (timeout) causes failure.
- Solo initiator (no other sessions) → auto-pass (immediate). 
- Timeout (`VOTE_TIMEOUT`) default is 60 seconds in this version (adjustable).
- Grace shutdown delay (`SHUTDOWN_DELAY`) default 30 seconds.

### Adjusting Timeout / Grace Period
Edit near top of `server/vote_shutdown.sh`:
```bash
VOTE_TIMEOUT=60       # seconds to wait for votes
SHUTDOWN_DELAY=30      # seconds after unanimous pass
```

### Changing Unanimity Requirement
Locate final result section where total yes/no/non-voters are computed:
```bash
if [[ $total_no -eq 0 && $yes_votes -eq $total_participants ]]; then
    # unanimous pass
fi
```
Replace with majority rule (example):
```bash
local needed=$(( (total_participants / 2) + 1 ))
if [[ $yes_votes -ge $needed ]]; then
    # majority pass logic
fi
```
Or supermajority (2/3):
```bash
local needed=$(( (total_participants * 2 + 2) / 3 ))
if [[ $yes_votes -ge $needed ]]; then
    # supermajority pass
fi
```
Remember to adjust documentation if you change the rule.

## 🧪 AWS Helper Library Usage

`lib_ec2.bat` exposes actions:
```
call lib_ec2.bat :GET_STATE [/quiet|/value]
call lib_ec2.bat :GET_PUBLIC_IP [/quiet|/value]
```
Return environment variables: `STATE`, `PUBLIC_IP` (and prints value unless quiet). Exit codes:
- 0 success
- 1 missing env vars
- 2 AWS CLI failure / empty
- 3 usage / unknown action

Capture example:
```batch
for /f %%S in ('call scripts\lib_ec2.bat :GET_STATE /value') do set CUR=%%S
```

## 🛠️ Batch Script Flags

| Script | Flags | Description |
|--------|-------|-------------|
| `start_server.bat` | `/auto` | Non-blocking (skips pauses) |
| | `/debug` | Verbose tracing |
| `shutdown_server.bat` | `/auto` | Non-interactive vote initiation |
| | `/debug` | Verbose tracing (sync + SSH) |
| `vote_shutdown.sh` | `--plain/-p` | Disable emojis in output |

## 🐚 Server Script Customization

Key sections to review in `vote_shutdown.sh`:
- `load_team_map` (robust parsing & CR removal)
- `get_connected_users` (relies on `who`; adapt if using multiplexed shells or tmux with different IP extraction semantics)
- Logging: `log_vote` to `/var/log/quorumstop-votes.log` (ensure writable; may require adjusting permissions / using a group)

### Disabling Emojis Globally
Change default:
```bash
PLAIN_MODE=1
```
Or always wrap broadcast functions to respect a custom environment flag.

## 🔐 IAM Permission Minimum (Client)

Provide the IAM entity used for CLI with:
```
ec2:DescribeInstances
(ec2:StartInstances if start allowed)
(ec2:StopInstances if stop allowed)
sts:GetCallerIdentity
```
Lock region via policy conditions if desired.

## 🧾 Audit & Logs

Server log lines example (UTC timestamps):
```
2025-08-01T17:03:22Z | VOTE_INITIATED | Alice | 203.0.113.10 | timeout=60 plain=0
2025-08-01T17:03:35Z | VOTE_CAST | Bob | 203.0.113.20 | yes
2025-08-01T17:03:44Z | VOTE_RESULT | Alice | 203.0.113.10 | PASS unanimous yes=2
```
Rotate manually or with logrotate if growth matters.

## 🩺 Testing Workflow

1. Run `scripts\test_aws.bat` – verify CLI, identity, describe access.
2. Start instance: `scripts\start_server.bat /debug` (watch IP update logic).
3. Open multiple SSH sessions (simulate additional users).
4. Initiate: `scripts\shutdown_server.bat /debug`.
5. Cast votes from sessions: `vote_shutdown yes|no`.
6. Confirm shutdown or fail path matches expectation.

## ❓ FAQ Snippets

**Q: Why is my new teammate not appearing in votes?**
A: Ensure `TEAM_COUNT` increased AND both `DEVn_IP` & `DEVn_NAME` set; re-run shutdown script (creates new `team.map`).

**Q: Server says IP "None"?**
A: Instance may be starting – wait until running state then retry `start_server.bat` to allow IP allocation.

**Q: Log not created?**
A: Ensure user has permission to write `/var/log`; consider changing `LOG_FILE` to user home if restricted.

---

Proceed to [Installation Guide](INSTALLATION.md) for first-time setup steps, or [Usage Guide](USAGE.md) for day‑to‑day commands.