# AWS EC2 QuorumStop — Project Structure & Roadmap (Updated)

Reflects introduction of dynamic roster sync (`team.map`), helper libraries, unanimous voting default, and audit logging.

## Repository Layout (Current)

```
aws-ec2-quorumstop/
├── README.md                       # High-level overview (unanimous voting, dynamic IP)
├── LICENSE
├── CONTRIBUTING.md
├── CHANGELOG.md
│
├── scripts/                        # Windows client automation (authoritative config lives here)
│   ├── config.sample.bat           # Template (tracked)
│   ├── config.bat                  # REAL CONFIG (ignored) – edit locally only
│   ├── start_server.bat            # Start instance, wait, resolve/persist public IP
│   ├── shutdown_server.bat         # Initiate vote, sync roster, conditional stop
│   ├── sync_team.bat               # Build & upload ~/.quorumstop/team.map
│   ├── lib_ec2.bat                 # AWS state & public IP helper (quiet/value modes)
│   ├── lib_update_config.bat       # Safe in-place SERVER_IP rewrite (marker-based)
│   ├── view_config.bat             # Render current effective config & roster
│   ├── test_aws.bat                # CLI / identity / describe diagnostic
│   ├── deploy_vote_script.bat      # (Optional helper) push server vote script (if used)
│   └── config.bat.bak / *.bak      # Local backups (ignored)
│
├── server/                         # Server-side components (EC2 host)
│   ├── vote_shutdown.sh            # Voting engine (loads dynamic team.map; log + grace)
│   └── install.sh                  # (Basic/placeholder) install helper (may evolve)
│
├── docs/                           # Documentation set (kept aligned with code)
│   ├── INSTALLATION.md             # Install & bootstrap (Elastic IP optional)
│   ├── CONFIGURATION.md            # Client & server tuning; unanimity overrides
│   ├── USAGE.md                    # Day-to-day flows & command semantics
│   ├── SECURITY.md                 # Hardening & IAM least privilege guidance
│   ├── TROUBLESHOOTING.md          # Diagnosis matrix & recovery steps
│   └── PROJECT_STRUCTURE.md        # (This file)
│
├── examples/                       # Example templates (will evolve)
│   ├── README.md
│   ├── team-3-developers/          # Legacy placeholder (to be modernized)
│   │   ├── README.md
│   │   └── config.bat              # Demonstrative sample (do not use verbatim)
│   └── team-5-developers/          # Legacy placeholder
│       ├── README.md
│       └── config.bat
│
├── tools/                          # Future interactive tooling
│   ├── README.md
│   ├── setup-wizard.bat            # Planned interactive config generator
│   └── sync-ip.bat                 # (Planned superseded by start_server logic)
│
└── (root files listing instance IPs) # Convenience references / scratch (optional)
```

### Generated / Runtime Artifacts (Not Tracked)
| Location | Purpose |
|----------|---------|
| `scripts/config.bat` | Local user/team configuration (ignored) |
| `~/.quorumstop/team.map` | Authoritative roster loaded by server vote script |
| `/var/log/quorumstop-votes.log` | Audit trail (UTC) of vote lifecycle |
| `/tmp/shutdown_vote/` | Ephemeral vote working files (removed after completion) |

## Data Flow Summary
```
config.bat ──(sync_team.bat)──> ~/.quorumstop/team.map ──> vote_shutdown.sh
                         │
                         └─(lib_ec2 + update)→ dynamic SERVER_IP persistence
```

## Key Script Responsibilities
| Script | Responsibility | Idempotence |
|--------|----------------|-------------|
| start_server.bat | Start instance if stopped, poll state, fetch & persist IP | Yes |
| shutdown_server.bat | Prepare vote (roster sync, IP check) then conditional stop | Yes (safe on rerun) |
| sync_team.bat | Deterministic team.map generation from DEVn vars | Yes |
| lib_ec2.bat | Abstract AWS queries (state, public IP) | Yes |
| lib_update_config.bat | Safe targeted SERVER_IP rewrite (marker anchored) | Yes |
| vote_shutdown.sh | Enforce unanimous voting + logging + grace | Per vote run |

## Unanimous Voting Default
- Connected users (via `who`) must all cast YES within timeout (non-vote = NO).
- Initiator auto-recorded YES; solo initiator auto-pass.
- Modify decision block in `vote_shutdown.sh` for majority / supermajority; update docs if changed.

## Roadmap (Help Wanted)
| Item | Description | Status |
|------|-------------|--------|
| Setup Wizard | `tools/setup-wizard.bat` for guided config creation & validation | Planned |
| Signed Roster | Optional signature/hmac for `team.map` integrity verification | Planned |
| Majority Mode Example | Provide toggled code snippet & docs for majority / supermajority | Planned |
| SSM Transport Option | Replace SSH with AWS SSM (no inbound 22) variant scripts | Planned |
| PowerShell Port | Native `.ps1` equivalents for batch scripts | Planned |
| GitHub CI | Workflow: shellcheck vote script + static batch linting | Planned |
| Log Rotation Doc | Add note for integrating with logrotate / Windows exporters | Planned |
| team.map Integrity Check | Server-side freshness (max age) optional enforcement | Planned |

## Deprecated / Legacy Notes
- Manual editing of `DEV_NAMES` inside `vote_shutdown.sh` is now fallback only; rely on sync.
- `sync-ip.bat` concept largely superseded by automatic update inside `start_server.bat` / `shutdown_server.bat`.

## Contribution Pointers
1. Open an Issue referencing roadmap item or improvement.
2. Discuss approach (especially for security-affecting changes).
3. Keep batch scripts minimal & defensive (explicit errorlevel checks).
4. Add/adjust documentation *with* feature PRs to prevent drift.

## Quick Maintenance Checks
| Task | Command |
|------|---------|
| Verify AWS access | `scripts\test_aws.bat` |
| View current config | `scripts\view_config.bat` |
| Start cycle | `scripts\start_server.bat /debug` |
| Initiate vote | `scripts\shutdown_server.bat /debug` |
| Inspect roster (server) | `cat ~/.quorumstop/team.map` |
| Inspect log | `tail -20 /var/log/quorumstop-votes.log` |

## Glossary
| Term | Meaning |
|------|---------|
| Roster | Mapping of IP → Name used in vote display and logs |
| team.map | Generated roster file uploaded per vote initiation |
| Unanimous | All connected users must vote YES; abstain counts NO |
| Grace Period | Delay after PASS allowing users to save work |
| Audit Log | Persistent record of each vote action/result |

---
For any structural change, update this file in the same PR to keep documentation synchronized.