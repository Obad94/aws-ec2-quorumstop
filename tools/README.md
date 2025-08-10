# Tools (Roadmap)

Planned / optional helper utilities complementing core batch scripts.

## Planned
- `setup-wizard.bat`  Interactive creation/validation of `config.bat` (instance lookup, key path check, roster input, test_aws integration)
- `report-status.bat`  Aggregate current state (instance status, last vote result tail, roster diff) for daily summary
- `schedule-shutdown-task.ps1`  Example PowerShell to register a Windows Scheduled Task running `shutdown_server.bat /auto`
- `migrate-iam-policy.bat`  Helper to print minimal least-privilege JSON with filled placeholders

## Re-evaluated
- `sync-ip.bat` Redundant: IP handling now embedded in `start_server.bat` / `shutdown_server.bat` with `lib_update_config.bat`.

## Contribution Notes
1. Prefer pure batch or PowerShell (no extra runtimes) for portability.
2. Keep output concise; integrate `/debug` flag for verbose diagnostics.
3. Add documentation entries (README + relevant doc) in same PR.

Open an issue before implementing a planned tool to avoid duplicate work.
