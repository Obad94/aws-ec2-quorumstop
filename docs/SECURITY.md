# Security Guide

This guide reflects the updated architecture (dynamic roster sync, unanimous voting default, helper libraries) and provides best practices for securing AWS EC2 QuorumStop.

## 🔒 Core Security Principles

1. **Least Privilege** – IAM identity only needs: describe, start, stop the single target instance + STS identity.
2. **Ephemeral State** – Voting artifacts live under `/tmp/shutdown_vote` and are removed after each vote.
3. **Authoritative Roster on Client** – Team list defined in `config.bat` → transmitted as `~/.quorumstop/team.map`; server fallback mappings are a *safety net* only.
4. **Tamper Visibility** – Vote lifecycle logged to `/var/log/quorumstop-votes.log` (UTC timestamps). Alterations or gaps indicate potential tampering.
5. **Secure Automation** – `/auto` mode avoids prompting; ensure automated runs originate from trusted machines / scheduled tasks with controlled credentials.

## 🔑 SSH Key Management

**✅ Best Practices:**

- **Individual SSH keys**: Each team member should have their own unique SSH key pair
- **Strong key generation**: Use RSA 4096-bit or Ed25519 keys
- **Passphrase protection**: Use strong passphrases for private keys
- **Regular rotation**: Rotate keys every 6 months
- **Secure storage**: Store private keys in encrypted folders/drives
- **No sharing**: Never share private keys via email, chat, or cloud storage

**Key Generation Example:**
```bash
# Generate RSA 4096-bit key
ssh-keygen -t rsa -b 4096 -C "your.email@company.com" -f ~/.ssh/ec2-quorumstop-key

# Or generate Ed25519 key (more secure, shorter)
ssh-keygen -t ed25519 -C "your.email@company.com" -f ~/.ssh/ec2-quorumstop-key
```

**❌ Security Anti-Patterns:**
- Sharing the same SSH key among team members
- Using keys without passphrases in shared environments
- Storing keys in unencrypted cloud storage
- Using default key names for multiple projects
- Never rotating keys

## 🪪 AWS IAM Security (Refined)

Minimal policy targeting one instance (replace REGION / ACCOUNT / INSTANCE_ID):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {"Effect": "Allow","Action": ["ec2:DescribeInstances"],"Resource": "*"},
    {"Effect": "Allow","Action": ["ec2:StartInstances","ec2:StopInstances"],"Resource": "arn:aws:ec2:REGION:ACCOUNT:instance/INSTANCE_ID"},
    {"Effect": "Allow","Action": ["sts:GetCallerIdentity"],"Resource": "*"}
  ]
}
```
Add optional conditions:
- `aws:SourceIp` restrict to office / team IP CIDRs.
- `aws:MultiFactorAuthPresent` true for manual interventions (optional if CI automation not required).

## 👥 Roster Integrity

The server no longer requires manual editing of `DEV_NAMES` for normal operation:
- Client `scripts/sync_team.bat` generates `team.map` each vote.
- Server script empties fallback map and loads `~/.quorumstop/team.map` if present.
- Missing or stale `team.map` ⇒ names may appear as `Unknown(<ip>)` (treat as warning – investigate sync path, SSH, or key issues).

**Hardening Tips:**
- Restrict `~/.quorumstop` permissions: `chmod 700 ~/.quorumstop`.
- Optionally verify file freshness before accepting vote: add a timestamp max-age check to `vote_shutdown.sh` (custom enhancement).

## 🗳️ Voting Security Model

Default rule: **UNANIMOUS** yes among *current connected* SSH users (initiator auto-YES). Non-vote = implicit NO. Solo initiator = auto-pass after safety grace.

Security implications:
- Prevents unilateral shutdown impacting active collaborators.
- Idle forgotten sessions can block (fail-safe). Encourage users to log out or implement an idle detection enhancement.
- To change to majority / supermajority you must modify server script logic – document any deviation for audit clarity.

## 🧾 Audit & Logging

Log path: `/var/log/quorumstop-votes.log`
Format (UTC):
```
2025-08-10T18:45:12Z | VOTE_INITIATED | Alice | 203.0.113.10 | timeout=60 plain=0
2025-08-10T18:45:20Z | VOTE_CAST | Bob | 203.0.113.20 | yes
2025-08-10T18:45:47Z | VOTE_RESULT | Alice | 203.0.113.10 | PASS unanimous yes=2
```
Apply restrictive permissions:
```bash
sudo touch /var/log/quorumstop-votes.log
sudo chown ubuntu:ubuntu /var/log/quorumstop-votes.log
sudo chmod 640 /var/log/quorumstop-votes.log
```
Optionally ship to CloudWatch Logs or aggregate via fluent-bit for centralized retention.

**Integrity Monitoring:**
- Monitor for truncation or sudden absence.
- Hash log (e.g., daily `sha256sum`) to detect tampering.

## 🧩 Script & File Permissions

**File Permissions:**
```bash
# Ensure vote script has proper permissions
chmod 755 /home/ubuntu/vote_shutdown.sh
chmod 700 /tmp/shutdown_vote  # Vote directory permissions

# Secure SSH configuration
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

**Roster directory**
```bash
chmod 700 ~/.quorumstop 2>/dev/null || true
# Remove world access from vote dir if created
[ -d /tmp/shutdown_vote ] && chmod 700 /tmp/shutdown_vote 2>/dev/null || true
```

## 🌐 Network Security

**Security Group Configuration:**

**✅ Secure Setup:**
```bash
# Allow SSH only from team member IPs
Type: SSH, Protocol: TCP, Port: 22, Source: 203.0.113.10/32 (Alice)
Type: SSH, Protocol: TCP, Port: 22, Source: 203.0.113.20/32 (Bob)  
Type: SSH, Protocol: TCP, Port: 22, Source: 203.0.113.30/32 (Carol)

# Application ports (if needed)
Type: HTTP, Protocol: TCP, Port: 80, Source: 0.0.0.0/0
Type: HTTPS, Protocol: TCP, Port: 443, Source: 0.0.0.0/0
```

**❌ Insecure Configuration:**
```bash
# NEVER do this
Type: SSH, Protocol: TCP, Port: 22, Source: 0.0.0.0/0  # Allows SSH from anywhere
```

**VPC Security Enhancements:**

1. **Private subnets**: Place EC2 instances in private subnets
2. **Bastion hosts**: Use dedicated bastion hosts for SSH access
3. **VPN access**: Require VPN connection before SSH access
4. **Network ACLs**: Additional layer of network filtering

## 🧪 Detection / Monitoring Enhancements

| Layer | Enhancement | Benefit |
|-------|-------------|---------|
| OS | `auditd` watch `/var/log/quorumstop-votes.log` | Vote log integrity |
| AWS | CloudTrail filter Start/Stop events | Correlate with logged votes |
| Network | VPC Flow Logs (rejects) | Spot scanning / abuse |
| Host | Fail2ban / UFW | Reduce brute force risk |

Add CloudTrail alarm if Start/Stop occurs without preceding `VOTE_RESULT PASS` in last N minutes (custom lambda / SIEM rule).

## 🚨 Incident Response (Adjusted)

If unauthorized stop detected:
1. Retrieve last 50 log lines: `tail -50 /var/log/quorumstop-votes.log`.
2. Compare timestamps with CloudTrail `StopInstances` event.
3. If mismatch → potential bypass (manual AWS console/API). Investigate IAM usage.

If roster poisoning suspected (team.map altered):
- Compare local client config roster vs server map: `diff <(sort team.map) <(cat expected_roster.txt)` (if you maintain a reference).
- Add signature (e.g., HMAC) future enhancement: clients append `# sig=<hash>` header verified server-side.

## 🛡️ Hardening Checklist

| Area | Action | Status |
|------|--------|--------|
| IAM | Least privilege policy applied |  |
| IAM | MFA enforced for interactive users |  |
| SSH | Per-user key pairs only |  |
| SSH | Security group restricted to team IPs / VPN |  |
| Roster | `~/.quorumstop` perms 700 |  |
| Logging | Vote log permissions 640 |  |
| Monitoring | CloudTrail alerts for Start/Stop |  |
| Integrity | Daily hash of vote log stored off-host |  |
| Updates | System packages auto-updated |  |
| Review | Monthly access & roster audit |  |

## 🔐 Advanced Options

### Systems Manager (SSM) Instead of SSH
- Eliminates inbound 22.
- All commands auditable in CloudTrail.
Adapt `shutdown_server.bat` to replace SSH command with SSM `send-command` invoking vote script (SSM document or direct shell). Ensure SSM IAM permissions added: `ssm:SendCommand`, `ssm:StartSession` plus instance role with `AmazonSSMManagedInstanceCore`.

### Signed Roster (Future Enhancement)
- Clients generate roster + detached signature.
- Server validates signature before loading to prevent on-path modification.

## 🧪 Root Credential Usage Warning

`test_aws.bat` surfaces root ARN pattern `:root$`. Treat root key discovery as a rotation emergency: delete root access keys, migrate to IAM roles/users with MFA.

## ❓ Quick FAQ

**Q: Should we still edit DEV_NAMES inside `vote_shutdown.sh`?**  
A: No – rely on synced `team.map`. Internal entries are fallback only.

**Q: Can a malicious user falsify names?**  
A: If they control *your* client config & can sync. Mitigate by restricting who can initiate votes (custom server-side IP allowlist) or adding signatures.

**Q: What stops a direct AWS console stop?**  
A: Nothing inherent; rely on IAM controls + alerting. Consider SCP (Service Control Policy) requiring condition tag unless a vote log event exists (advanced pattern).

---
Security is iterative—review logs, refine IAM, and automate checks.