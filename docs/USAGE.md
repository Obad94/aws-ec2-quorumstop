# Usage Guide

Updated for unanimous voting default, dynamic team map syncing, and enhanced helper scripts.

## 🚀 Quick Reference

| Command | Purpose | Common Time |
|---------|---------|-------------|
| `scripts/start_server.bat` | Start instance / sync IP | Start of day |
| `scripts/shutdown_server.bat` | Initiate unanimous shutdown vote | End of day |
| `scripts/view_config.bat` | Display effective configuration | Anytime |
| `scripts/test_aws.bat` | Validate AWS CLI & permissions | Setup / Debug |
| `scripts/sync_team.bat` | Manually push roster (team.map) | Rare/manual |

Flags:
```
/start scripts
  /debug  Verbose internal tracing
  /auto   Non-interactive (skip pauses)
Server vote script
  vote_shutdown [--plain] yes|no|status|debug|help
```

## 🗓️ Daily Flow

### 1. Start Work
```batch
scripts\start_server.bat
```
- If instance stopped → starts & waits until running
- Resolves public IP (retries), updates `SERVER_IP` in `config.bat` if changed
- Safe to run multiple times (idempotent)

### 2. Use the Server
SSH once IP shown:
```powershell
ssh -i C:\path\to\key.pem ubuntu@<SERVER_IP>
```
Open additional sessions as needed (each counts as connected user during votes).

### 3. End of Day Vote
```batch
scripts\shutdown_server.bat
```
Sequence:
1. Confirm running state
2. Refresh public IP if drifted
3. Generate & upload `~/.quorumstop/team.map`
4. Initiate vote (initiator auto YES)
5. Broadcast instructions (emoji unless users opt `--plain` when casting)
6. Wait up to `VOTE_TIMEOUT` (default 60s) for all other connected users
7. Unanimous? → 30s grace → AWS stop command; else abort

Use `/debug` for detailed path; `/auto` for unattended invocation (no pauses, reduced chatter).

## 🗳️ Voting Mechanics

Rule (default): EVERY connected user must vote YES. Non-vote = NO. Solo initiator = automatic pass.

### Casting Votes (Server Session)
```bash
vote_shutdown yes   # Agree to shutdown
vote_shutdown no    # Reject shutdown
vote_shutdown status
vote_shutdown debug --plain
```
If you did not create a symlink, run `~/vote_shutdown.sh` instead of `vote_shutdown`.

### Example Broadcast (Plain Text Equivalent)
```
============================================
VOTE  SERVER SHUTDOWN VOTE
============================================
Initiated by: Alice
Reason: Save AWS costs
Time: 17:45 UTC

TIME You have 1 MINUTES to vote:
YES  To AGREE to shutdown:
     vote_shutdown yes
NO   To REJECT shutdown:
     vote_shutdown no
WARN  No vote = NO vote (server stays online)
============================================
```

### Progress Updates
Periodic lines (every 10s):
```
TIME Time remaining: 40s | VOTE Votes received: 1/2
```
`1/2` means 1 (of 2 other users) has cast a vote; initiator’s auto YES not counted in that progress ratio.

### Final Result (Pass)
```
RESULT FINAL RESULTS:
YES YES votes: 3
NO  NO votes: 0 (explicit)
INFO Non-voters: 0 (counted as NO)
RESULT Total NO: 0
PASS RESULT: VOTE PASSED - Unanimous approval, shutdown proceeding!
SHUTDOWN Server will shutdown in 30 seconds...
SAVE SAVE YOUR WORK NOW!
```

### Final Result (Fail - Missing Vote)
```
RESULT FINAL RESULTS:
YES YES votes: 2
NO  NO votes: 0 (explicit)
INFO Non-voters: 1 (counted as NO)
RESULT Total NO: 1
FAIL RESULT: VOTE FAILED - Not unanimous, shutdown cancelled.
```

### Final Result (Fail - Explicit NO)
```
RESULT FINAL RESULTS:
YES YES votes: 2
NO  NO votes: 1 (explicit)
INFO Non-voters: 0 (counted as NO)
RESULT Total NO: 1
FAIL RESULT: VOTE FAILED - Not unanimous, shutdown cancelled.
```

## 🔄 Roster Sync Logic

`scripts\sync_team.bat` builds `team.map` from `TEAM_COUNT` and `DEVn_*` variables:
```
IP NAME
```
Uploaded to `~/.quorumstop/team.map` on each shutdown attempt. The server script:
1. Clears internal fallback names.
2. Loads the uploaded file (ignoring comments / empty lines, stripping CR).
3. Uses it for vote naming & logs.

If sync fails, fallback names remain (might not match real team). Fix SSH or key path and retry.

## 👀 Viewing Configuration

```batch
scripts\view_config.bat
```
Shows:
- Instance details
- Current persisted `SERVER_IP`
- Team entries (with indices)
- Last modified time of `config.bat`

## 🧪 Diagnostics

### AWS Environment
```batch
scripts\test_aws.bat
```
Checks: CLI presence → identity → describe instance.

### Manual State / IP Queries
Using helper library directly:
```batch
call scripts\lib_ec2.bat :GET_STATE
call scripts\lib_ec2.bat :GET_PUBLIC_IP
```
Quiet/raw capture:
```batch
for /f %%S in ('call scripts\lib_ec2.bat :GET_STATE /value') do set CUR_STATE=%%S
```

### Server Debug
On EC2:
```bash
vote_shutdown debug --plain
```
Displays connection env, user detection, current vote directory content.

## 🛑 Emergency Stop (Bypass Vote)
Only if necessary (e.g., stuck cost issue):
```powershell
aws ec2 stop-instances --instance-ids <INSTANCE_ID>
```
Document the reason; consider adding a team message.

## 🔁 Restart Cycle
If you stopped the instance earlier:
```batch
scripts\start_server.bat /debug
```
Expect IP to refresh (unless Elastic IP bound). Then normal SSH usage resumes.

## 🧩 Customizing Voting Rule
Edit `vote_shutdown.sh` final decision block to adopt majority / supermajority. Update all docs/team once changed. Keep logic symmetrical with broadcast instructions.

Example majority patch:
```bash
local total=$total_participants
local need=$(( total/2 + 1 ))
if [[ $yes_votes -ge $need ]]; then
  # PASS majority
fi
```

## 🧾 Audit Log
`/var/log/quorumstop-votes.log` lines (UTC):
```
2025-08-10T18:10:01Z | VOTE_INITIATED | Alice | 203.0.113.10 | timeout=60 plain=0
2025-08-10T18:10:08Z | VOTE_CAST | Bob | 203.0.113.20 | yes
2025-08-10T18:10:13Z | VOTE_RESULT | Alice | 203.0.113.10 | PASS unanimous yes=2
```
If missing: verify write permissions or adjust log path in script.

## 🐞 Troubleshooting Matrix

| Issue | Likely Cause | Action |
|-------|--------------|--------|
| IP stays 0.0.0.0 | Instance not running / no IP yet | Wait then rerun `start_server.bat` |
| Vote always fails | Uncast vote (abstention) | Run `who` on server; close idle SSH sessions or have user vote |
| SSH 255 on shutdown | Key path wrong / permissions / SG ingress | Fix path or SG rule, test manual SSH |
| team.map not updating | Sync failure / wrong KEY_FILE | Run `scripts\sync_team.bat` without /auto to view errors |
| STATE blank | AWS CLI credentials invalid | `aws sts get-caller-identity` then reconfigure |

## 💡 Tips

- Use Elastic IP to eliminate daily IP churn.
- Schedule a Windows Task with `/auto` to attempt shutdown at a standard time (vote will fail safely if others online and not unanimous).
- Keep `TEAM_COUNT` accurate; stray higher DEV entries ignored but may confuse maintainers.
- Use `--plain` if terminal lacks emoji support.

## 🔐 Safety Principles

- Non-vote = NO ensures no silent shutdown.
- Solo user auto-pass encourages cost savings without friction.
- All logic is client-transparent; inspect batch and shell scripts freely.

---
Next: Review [Security Guide](SECURITY.md) or revisit [Configuration Guide](CONFIGURATION.md).