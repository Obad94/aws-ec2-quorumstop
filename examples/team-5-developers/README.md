# Team of 5 Developers Example

Sample (non-production) `config.bat` pattern for five developers. Do NOT include real secrets or IPs in committed examples.

```batch
@echo off
REM === QuorumStop Example Config (5 Devs) ===
set INSTANCE_ID=i-0EXAMPLEABCDE9999
set AWS_REGION=us-east-1
set SERVER_IP=0.0.0.0                  REM Auto-updated by scripts
set KEY_FILE=C:\Keys\team5-example.pem
set SERVER_USER=ubuntu
set SERVER_VOTE_SCRIPT=/home/ubuntu/vote_shutdown.sh

set TEAM_COUNT=5
set DEV1_IP=198.51.100.11 & set DEV1_NAME=Anna
set DEV2_IP=198.51.100.12 & set DEV2_NAME=Ben
set DEV3_IP=198.51.100.13 & set DEV3_NAME=Chloe
set DEV4_IP=198.51.100.14 & set DEV4_NAME=Dan
set DEV5_IP=198.51.100.15 & set DEV5_NAME=Elle

REM Local identity (each developer customizes below 2 lines in their copy)
set YOUR_NAME=Anna
set YOUR_IP=%DEV1_IP%
```

Guidelines:
- Increment `TEAM_COUNT` when adding/removing roster slots.
- Keep variable names sequential (DEV1..DEV5) for predictable iteration.
- Unanimous YES of all connected SSH sessions required for shutdown (non-vote = NO).
- Solo initiator auto-pass.
- `sync_team.bat` uploads roster as `~/.quorumstop/team.map` each vote attempt.

Extending beyond 5 developers:
```
set TEAM_COUNT=7
set DEV6_IP=198.51.100.16 & set DEV6_NAME=Fiona
set DEV7_IP=198.51.100.17 & set DEV7_NAME=Gabe
```

See `docs/CONFIGURATION.md` for advanced patterns and `docs/USAGE.md` for workflow.
