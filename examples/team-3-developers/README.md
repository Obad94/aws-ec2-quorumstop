# Team of 3 Developers (Example)

Illustrative (non-functional) `config.bat` pattern for a 3‑developer roster using dynamic IP persistence and unanimous voting.

Use RFC 5737 test IPs only; replace with real values locally (never commit secrets).

```batch
@echo off
REM === QuorumStop Example Config (3 Devs) ===
set INSTANCE_ID=i-0EXAMPLEABCDEF123
set AWS_REGION=us-west-2
set SERVER_IP=0.0.0.0                 REM Placeholder; scripts will update
set KEY_FILE=C:\Keys\example-team.pem
set SERVER_USER=ubuntu
set SERVER_VOTE_SCRIPT=/home/ubuntu/vote_shutdown.sh

REM Team roster (authoritative)
set TEAM_COUNT=3
set DEV1_IP=203.0.113.10
set DEV1_NAME=Alice
set DEV2_IP=203.0.113.20
set DEV2_NAME=Bob
set DEV3_IP=203.0.113.30
set DEV3_NAME=Carol

REM Local identity (each developer sets these two lines uniquely)
set YOUR_NAME=Alice
set YOUR_IP=%DEV1_IP%
```

Notes:
- Keep `TEAM_COUNT` aligned with highest sequential DEV index.
- Each teammate copies template then changes ONLY `YOUR_NAME` / `YOUR_IP`.
- `SERVER_IP` becomes real after first successful `start_server.bat` run.
- Shutdown requires unanimous YES of connected SSH sessions (solo initiator auto-pass).

For more detail see `docs/CONFIGURATION.md` and `docs/USAGE.md`.
