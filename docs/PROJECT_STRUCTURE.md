# AWS EC2 QuorumStop — Project Structure and Roadmap

This document outlines the repository layout, including what exists today and what’s planned. Planned items are kept here intentionally with guidance so contributors can help build them.

## Current Structure

```
aws-ec2-quorumstop/
├── README.md                     # Main project documentation
├── LICENSE                       # MIT License
├── CONTRIBUTING.md               # Contribution guidelines
│
├── scripts/                      # Windows client scripts (canonical)
│   ├── config.bat                # Configuration file (edit this)
│   ├── start_server.bat          # Server startup script
│   ├── shutdown_server.bat       # Democratic shutdown script
│   ├── view_config.bat           # Configuration viewer
│   └── test_aws.bat              # AWS connectivity test
│
├── server/                       # Server-side components (run on EC2)
│   ├── vote_shutdown.sh          # Server-side voting script
│   └── install.sh                # Server setup automation script
│
├── docs/                         # Documentation
│   ├── INSTALLATION.md           # Installation guide
│   ├── CONFIGURATION.md          # Configuration guide
│   ├── USAGE.md                  # Usage guide
│   ├── SECURITY.md               # Security best practices
│   └── TROUBLESHOOTING.md        # Troubleshooting guide
```

## Planned Additions (help wanted)

These do not exist yet. They are documented here with guidelines for contributors.

- CHANGELOG.md (planned)
  - Purpose: Track notable changes per release.
  - Guideline: Keep to Keep a Changelog format; update on each PR that changes behavior.

- .github/ (scaffolded)
  - ISSUE_TEMPLATE/bug_report.yml (added)
  - ISSUE_TEMPLATE/feature_request.yml (added)
  - workflows/ci.yml (added; minimal shellcheck + placeholder batch validation)

- examples/ (scaffolded)
  - README.md (added)
  - team-3-developers/README.md (added)
  - team-3-developers/config.bat (sample, non-functional placeholder)

- tools/ (scaffolded)
  - README.md (added)
  - setup-wizard.bat (stub)
  - sync-ip.bat (stub)

If you’d like to pick one of these up, open an issue to discuss scope and design.

## Quick Start

1) Launch EC2 instance
- Use Amazon Linux 2, t2.micro (or larger). Allow SSH (22) from your IP.

2) Connect to EC2
```bash
ssh -i "your-key.pem" ec2-user@your-ec2-public-dns
```

3) Install dependencies (on EC2)
```bash
sudo yum update -y
sudo yum install -y git aws-cli
```

4) Clone the repository
```bash
git clone https://github.com/Obad94/aws-ec2-quorumstop.git
cd aws-ec2-quorumstop
```

5) Configure the client (Windows)
- Current: Edit `scripts/config.bat` and set your instance ID, region, key file, and team members. See `docs/CONFIGURATION.md`.
- Planned: Copy from `examples/team-3-developers/config.bat` once examples are added.

6) Setup wizard (planned)
- tools/setup-wizard.bat will guide config creation and AWS checks. Until then, follow step 5 and run `scripts/test_aws.bat`.

7) Start the server (from Windows)
```bat
scripts\start_server.bat
```

8) Test democratic shutdown (from Windows)
```bat
scripts\shutdown_server.bat
```

9) View configuration
```bat
scripts\view_config.bat
```

10) Check AWS connectivity
```bat
scripts\test_aws.bat
```

## Contributing

We welcome contributions. See `CONTRIBUTING.md` for workflow and coding guidelines. For planned items above, please comment on or create an issue before starting work.

## License

MIT License. See `LICENSE`.

## Support

Open an issue or start a discussion in the repository.