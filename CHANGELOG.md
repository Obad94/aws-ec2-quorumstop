# Changelog

## [0.1.11] - 2025-08-10
### Added
- SYNC_ERR diagnostic output and clear sync success/fail messaging in `shutdown_server.bat`.
- Label-based flow (`SYNC_OK`, `AFTER_SYNC`) to simplify control after team sync.
### Changed
- Refactored `shutdown_server.bat` post-sync logic to eliminate fragile nested single-line IF/ELSE constructs.
- Rewrote `sync_team.bat` loop to use delayed expansion safely (removed `call if` misuse) and reset temp vars each iteration.
- Simplified team entry display in `config.bat` (removed parentheses that broke enclosing `for` block) for reliable rendering.
### Fixed
- Eliminated recurring `. was unexpected at this time.` batch parser error by removing problematic parenthesized IF blocks.
- Resolved `'if' is not recognized` errors caused by malformed `call if` sequences in `sync_team.bat`.
- Ensured dynamic `team.map` properly parsed so initiator name appears (no longer shows `Unknown(IP)` when sync succeeds).
- Prevented duplicate/hidden failures of team map generation by surfacing sync status and gating fallback messaging.

## [0.1.10] - 2025-08-10
### Changed
- `deploy_vote_script.bat`: Added /debug flag-controlled verbose output (suppressed unless /debug supplied).
- `deploy_vote_script.bat`: Added /force handling separated from debug and improved control flow.
- `deploy_vote_script.bat`: Show local SHA256 hash and remote hash with case normalization differences clarified.
- `deploy_vote_script.bat`: Prevents verification (New Remote Hash) when no upload performed.
### Fixed
- Escaped & in echo lines to avoid premature command termination.
- Eliminated early exit due to parsing errors (". was unexpected") by refactoring parenthesis blocks.
- Ensured script returns 0 on success and non-zero only on real errors.
### Added
- Conditional remote hash verification only after actual upload; internal DID_UPLOAD flag.
- Unified flag parsing for /debug and /force.

## [0.1.9] - 2025-08-10
### Fixed
- **Critical Fix**: Resolved duplicate SERVER_IP entries in config.bat caused by faulty deduplication logic in lib_update_config.bat
- **Critical Fix**: Fixed variable scoping issues in Windows batch loops by completely rewriting the update mechanism to use a two-step approach (remove all SERVER_IP lines, then add exactly one back)
- Improved error handling and debugging output in lib_update_config.bat with proper /quiet and /debug flag support

### Changed
- **Major Refactor**: Completely rewrote lib_update_config.bat to eliminate duplicate SERVER_IP line issues using a clean slate approach
- **Streamlined Scripts**: Simplified and cleaned up deploy_vote_script.bat, start_server.bat, and shutdown_server.bat for better maintainability
- Enhanced start_server.bat and shutdown_server.bat with improved /debug and /auto flag support for better automation
- Improved shutdown_server.bat with dynamic IP persistence via server_ip.txt file
- Optimized deploy_vote_script.bat with more concise error handling and cleaner output

### Added
- Enhanced debugging capabilities across all core scripts with consistent /debug flag support
- Runtime IP persistence mechanism in shutdown_server.bat to maintain IP state between script runs
- Better automation support with improved /auto flag handling in start_server.bat and shutdown_server.bat

## [0.1.8] - 2025-08-09
### Fixed
- **Critical Fix**: Resolved encoding issues in `scripts/lib_ec2.bat` that caused execution failures
- **Critical Fix**: Fixed hash computation in `scripts/deploy_vote_script.bat` by replacing unreliable certutil with PowerShell Get-FileHash
- **Critical Fix**: Corrected SSH command syntax in deployment script (removed problematic `\$1` escaping that caused "unexpected . at this time" errors)
- **Critical Fix**: Fixed delayed expansion issues in batch files causing variable assignment failures
- **Critical Fix**: Resolved config.bat variable scoping issues that prevented environment variables from being properly exported
- Improved error handling and debugging output in both lib_ec2.bat and deploy_vote_script.bat
- Enhanced hash comparison logic with proper delayed expansion syntax
- Fixed AWS CLI command execution with proper variable substitution

## [0.1.7] - 2025-08-09
### Changed
- Enhanced `scripts/config.bat` for simplified variable declarations and removed inline display logic.
- Improved `scripts/start_server.bat` for robust execution and dynamic team entry display.
### Fixed
- Resolved formatting issues in team entries displayed by `scripts/start_server.bat`.

## [0.1.6] - 2025-08-09
### Added
- `scripts/sync_team.bat` to dynamically generate and upload team.map to server.
- Dynamic team map loading in `server/vote_shutdown.sh` to show updated developer names during voting.
- `scripts/deploy_vote_script.bat` automated deployment & hashing for server vote script.
### Changed
- `shutdown_server.bat` now calls `sync_team.bat` before initiating vote to ensure names are current.
- Improved automation for syncing developer mappings between Windows and server scripts.
### Fixed
- Prevented manual edits to team names in `server/vote_shutdown.sh` by introducing dynamic syncing.

## [0.1.5] - 2025-08-09
### Added
- Shared `scripts/lib_ec2.bat` for reusable EC2 instance state and public IP retrieval.
- `server/vote_shutdown.sh` now supports `--plain`/`-p` mode for emoji-free output (for minimal terminals).
- Remote script existence check before initiating vote in `shutdown_server.bat`.
### Changed
- Refactored `start_server.bat` and `shutdown_server.bat` to use `lib_ec2.bat` for all AWS status/IP polling, reducing code duplication and improving reliability.
- Improved configuration validation and error messages in both startup and shutdown scripts.
- Hardened `lib_update_config.bat` for future escaping and clarified header.
- Enhanced `vote_shutdown.sh` with safer logging, clearer output, and improved portability.
### Fixed
- All scripts now robustly handle missing/invalid config, SSH key, and AWS CLI errors with clearer guidance.

## [0.1.4] - 2025-08-09
### Changed
- Improved `scripts/test_aws.bat`: robust error handling, explicit exit code checks, root credential warning, and condensed EC2 instance summary output.

## [0.1.3] - 2025-08-09
### Changed
- Enhanced config compatibility: added TEAM_COUNT, DEVn_NAME, and show block to all example configs.
- Fixed display loop in scripts\config.bat for correct variable expansion.
- Added placeholder IP (0.0.0.0) guards to start_server.bat and shutdown_server.bat for safer operation.
- Harmonized setup-wizard.bat output header to clarify auto-update behavior.

# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning (when formal releases begin).

## [Unreleased]
### Added
- Shared `lib_update_config.bat` to eliminate duplicate UPDATE_CONFIG logic
- Implemented `tools/setup-wizard.bat` interactive configuration generator
- Implemented `tools/sync-ip.bat` lightweight IP refresh utility
- Dynamic enumeration of DEVn_IP variables in config updates and display
- Elastic IP guidance section added to `docs/INSTALLATION.md`
- Example multi-user configs: `examples/team-5-developers/`
- `scripts/config.sample.bat` template and .gitignore rules to prevent committing personal config / keys
### Changed
- `start_server.bat` and `shutdown_server.bat` now call shared library for config updates
- Updated examples README with roadmap and usage notes
### Fixed
- `tools/setup-wizard.bat`: Correct YOUR_NAME / YOUR_IP mapping (previously could write literal CHOICE); unified selection (index, DEVn, DEVn_IP, or full IP) and shows chosen mapping before write
- `scripts/view_config.bat`: Renders configuration directly instead of relying on inline display block inside `config.bat`, fixing blank DEVn_IP entries
- Prevents accidental literal placeholder values being persisted in `config.bat`
- Added .gitignore rules to exclude real `scripts/config.bat` and private key files
### Planned
- PowerShell module variants & Pester tests (next)
- CI workflow with ShellCheck + Pester + batch lint

## [0.1.2] - 2025-08-09
### Added
- .editorconfig and .gitattributes for consistent line endings & style
- GitHub issue templates (bug_report, feature_request)
- CI workflow scaffold (bash ShellCheck, placeholder batch check)
- Audit logging to /var/log/quorumstop-votes.log in server vote script
- Status badge placeholders in README

### Changed
- start_server.bat and shutdown_server.bat: skip config rewrite when IP unchanged
- Consistent quoting of KEY_FILE and minor echo clarifications

### Planned
- Refactor shared UPDATE_CONFIG into a dedicated helper script (next step)

## [0.1.1] - 2025-08-08
- Docs: Align PROJECT_STRUCTURE to reflect current files; standardize SSH user (ubuntu)
- Docs: Clarify initiator voting behavior in USAGE; add PowerShell Test-NetConnection tip
- Docs: Update INSTALLATION and TROUBLESHOOTING to prefer PowerShell examples over telnet
- Scripts: shutdown_server.bat guard when SERVER_IP is empty/None; clearer SSH failure guidance
- Scripts: start_server.bat retries for public IP assignment after running
- Server: vote_shutdown.sh harden vote dir perms (chmod 700) and clarify debug output
- Planned: examples/ and tools/ utilities maturation

## [0.1.0] - 2025-08-08
### Added
- Repository scaffolding for planned areas: `examples/`, `tools/`

### Changed
- Standardized project name to "AWS EC2 QuorumStop"
- Restructured repository into `scripts/` (Windows) and `server/` (EC2)
- Removed root wrapper scripts; updated docs to use `scripts/` and `server/` paths only
- Updated documentation and links; corrected installer/raw URLs

### Fixed
- Removed/updated placeholder references and mismatched paths in docs
