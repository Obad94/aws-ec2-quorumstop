# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning (when formal releases begin).

## [Unreleased]
- Docs: Align commands to scripts\ paths; fix outdated names and examples
- Docs: Voting window clarified to 5 minutes
- Scripts: Add AWS CLI presence check and AWS_PAGER disable in start/shutdown
- Scripts: Add SSH key existence check before voting
- Planned: examples/, tools/ utilities maturation
- Planned: setup wizard and sync helpers

## [0.1.0] - 2025-08-08
### Added
- Repository scaffolding for planned areas: `.github/`, `examples/`, `tools/`
- Issue templates and minimal CI workflow

### Changed
- Standardized project name to "AWS EC2 QuorumStop"
- Restructured repository into `scripts/` (Windows) and `server/` (EC2)
- Removed root wrapper scripts; updated docs to use `scripts/` and `server/` paths only
- Updated documentation and links; corrected installer/raw URLs

### Fixed
- Removed/updated placeholder references and mismatched paths in docs
