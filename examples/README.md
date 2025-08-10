# Examples

Updated to reflect dynamic roster syncing (team.map) and unanimous voting default.

Available sample folders (placeholders to be modernized):
- `team-3-developers/` – Minimal 3‑developer config pattern
- `team-5-developers/` – Extended roster example

Guidelines:
- Use ONLY RFC 5737 test blocks (203.0.113.x, 198.51.100.x, 192.0.2.x) in committed examples.
- Never include real instance IDs, keys, or public IPs.
- Demonstrate `TEAM_COUNT`, paired `DEVn_IP` + `DEVn_NAME`, and `YOUR_NAME`/`YOUR_IP`.
- Omit `SERVER_IP` (or set 0.0.0.0) – startup script will populate it.

Voting Model (examples assume):
- Unanimous YES of connected SSH sessions (initiator auto YES; solo auto-pass).

Example snippet pattern:
```batch
REM Example (do NOT use in production)
set INSTANCE_ID=i-0EXAMPLE123456789
set AWS_REGION=us-west-2
set SERVER_IP=0.0.0.0
set KEY_FILE=C:\Keys\example.pem
set SERVER_USER=ubuntu
set SERVER_VOTE_SCRIPT=/home/ubuntu/vote_shutdown.sh

set TEAM_COUNT=3
set DEV1_IP=203.0.113.10 & set DEV1_NAME=Alice
set DEV2_IP=203.0.113.20 & set DEV2_NAME=Bob
set DEV3_IP=203.0.113.30 & set DEV3_NAME=Carol

set YOUR_NAME=Alice
set YOUR_IP=%DEV1_IP%
```

Planned additions:
- `elastic-ip-config/` (showing stable IP workflow)
- Split-team / multi-instance scenario examples

Contributing:
Open an issue before expanding or replacing examples to keep style consistent.
