# AWS EC2 QuorumStop — Project Structure and Roadmap

This document outlines the repository layout, including what exists today and what’s planned. Planned items are kept here intentionally with guidance so contributors can help build them.

## Current Structure

```
aws-ec2-quorumstop/
├── README.md                     # Main project documentation
├── LICENSE                       # MIT License
├── CONTRIBUTING.md               # Contribution guidelines
├── CHANGELOG.md                  # Notable changes per release
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
│
├── examples/                     # Scaffolded examples (placeholders)
│   ├── README.md
│   └── team-3-developers/
│       ├── README.md
│       └── config.bat            # Sample (non-functional placeholder)
│
└── tools/                        # Scaffolded tools (stubs)
    ├── README.md
    ├── setup-wizard.bat          # Planned stub
    └── sync-ip.bat               # Planned stub
```

## Planned Additions (help wanted)

These do not exist yet. They are documented here with guidelines for contributors.

- .github/
  - ISSUE_TEMPLATE/bug_report.yml (planned)
  - ISSUE_TEMPLATE/feature_request.yml (planned)
  - workflows/ci.yml (planned; shellcheck + basic batch validation)

- Examples (upgrade)
  - Provide a minimal working `config.bat` sample for a 2–3 developer team (no secrets)

- Tools (upgrade)
  - Implement `setup-wizard.bat` (interactive config + AWS checks)
  - Implement `sync-ip.bat` (update SERVER_IP via AWS CLI)

If you’d like to pick one of these up, open an issue to discuss scope and design.

## Quick Start

1) Launch EC2 instance
- Use Ubuntu (e.g., 22.04 LTS), t2.micro (or larger). Allow SSH (22) from your IP.

2) Connect to EC2
```bash
ssh -i "your-key.pem" ubuntu@your-ec2-public-dns
```

3) Install dependencies (on EC2)
```bash
sudo apt update -y
sudo apt install -y git awscli
```

4) Clone the repository
```bash
git clone https://github.com/Obad94/aws-ec2-quorumstop.git
cd aws-ec2-quorumstop
```

5) Configure the client (Windows)
- Current: Edit `scripts/config.bat` and set your instance ID, region, key file, and team members. See `docs/CONFIGURATION.md`.
- Planned: Copy from `examples/team-3-developers/config.bat` once examples are upgraded to a working sample.

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