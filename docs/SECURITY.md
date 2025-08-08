# Security Guide

This guide covers security best practices for the AWS EC2 QuorumStop system.

## 🔒 Core Security Principles

Security should be a team responsibility. This guide helps you implement proper safeguards while maintaining the collaborative nature of the democratic shutdown system.

### 1. SSH Key Management

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

### 2. AWS IAM Security

**Principle of Least Privilege:**

Create a dedicated IAM policy with minimal required permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:StartInstances",
                "ec2:StopInstances"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "ec2:ResourceTag/Project": "QuorumStop"
                }
            }
        }
    ]
}
```

**Enhanced Security Options:**

1. **MFA Requirement:**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:StartInstances",
                "ec2:StopInstances"
            ],
            "Resource": "*",
            "Condition": {
                "Bool": {
                    "aws:MultiFactorAuthPresent": "true"
                },
                "NumericLessThan": {
                    "aws:MultiFactorAuthAge": "3600"
                }
            }
        }
    ]
}
```

2. **Time-based restrictions:**
```json
{
    "Condition": {
        "DateGreaterThan": {
            "aws:CurrentTime": "08:00Z"
        },
        "DateLessThan": {
            "aws:CurrentTime": "18:00Z"
        }
    }
}
```

3. **IP-based restrictions:**
```json
{
    "Condition": {
        "IpAddress": {
            "aws:SourceIp": [
                "203.0.113.10/32",
                "203.0.113.20/32",
                "203.0.113.30/32"
            ]
        }
    }
}
```

### 3. Network Security

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

### 4. Server-Side Security

**File Permissions:**
```bash
# Ensure vote script has proper permissions
chmod 755 /home/ubuntu/vote_shutdown.sh
chmod 700 /tmp/shutdown_vote  # Vote directory permissions

# Secure SSH configuration
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

**System Hardening:**
```bash
# Keep system updated
sudo apt update && sudo apt upgrade -y

# Install security updates automatically
sudo apt install unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades

# Configure firewall
sudo ufw enable
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

**Monitoring and Logging:**
```bash
# Enable detailed SSH logging
echo "LogLevel VERBOSE" | sudo tee -a /etc/ssh/sshd_config

# Monitor authentication attempts
sudo tail -f /var/log/auth.log

# Set up log rotation
sudo logrotate -f /etc/logrotate.conf
```

## 🔍 Monitoring and Auditing

### 1. AWS CloudTrail

Enable CloudTrail to monitor all API calls:

```json
{
    "eventSource": "ec2.amazonaws.com",
    "eventName": "StartInstances",
    "sourceIPAddress": "203.0.113.10",
    "userIdentity": {
        "userName": "alice",
        "principalId": "AIDAI23HZ27SI6FQMGNQ2"
    },
    "resources": [
        {
            "resourceType": "AWS::EC2::Instance",
            "resourceName": "i-1234567890abcdef0"
        }
    ]
}
```

### 2. Vote Audit Trail

**Enhanced logging in vote script:**
```bash
# Add to vote_shutdown.sh
LOG_FILE="/var/log/quorumstop-votes.log"

log_vote() {
    local action="$1"
    local user="$2" 
    local ip="$3"
    local result="$4"
    
    echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') | $action | $user | $ip | $result" >> "$LOG_FILE"
}

# Usage in script
log_vote "VOTE_INITIATED" "$initiator_name" "$initiator_ip" "SUCCESS"
log_vote "VOTE_CAST" "$user_name" "$user_ip" "$vote"
log_vote "VOTE_RESULT" "SYSTEM" "$initiator_ip" "$final_result"
```

### 3. Regular Security Reviews

**Weekly Checklist:**
- [ ] Review AWS CloudTrail logs for unusual activity
- [ ] Check security group rules for changes
- [ ] Verify team member IP addresses are still current
- [ ] Review vote logs for suspicious patterns
- [ ] Monitor AWS costs for unexpected charges

**Monthly Checklist:**
- [ ] Rotate SSH keys (if policy requires)
- [ ] Update server packages and security patches
- [ ] Review IAM policies and permissions
- [ ] Audit team member access levels
- [ ] Test backup and recovery procedures

**Quarterly Checklist:**
- [ ] Comprehensive security assessment
- [ ] Review and update security policies
- [ ] Team security training refresh
- [ ] Penetration testing (if applicable)
- [ ] Disaster recovery testing

## 🚨 Incident Response

### 1. Compromised SSH Key

**Immediate Actions:**
```bash
# 1. Remove compromised key from server
ssh -i "backup-key.pem" ubuntu@server
nano ~/.ssh/authorized_keys  # Remove compromised key line

# 2. Update security group to block compromised source IP
aws ec2 revoke-security-group-ingress \
    --group-id sg-12345678 \
    --protocol tcp \
    --port 22 \
    --cidr 203.0.113.999/32

# 3. Generate new key pair
ssh-keygen -t ed25519 -C "replacement-key" -f ~/.ssh/new-quorumstop-key

# 4. Add new key to server
ssh-copy-id -i ~/.ssh/new-quorumstop-key.pub ubuntu@server
```

**Recovery Steps:**
1. Investigate compromise source
2. Update config.bat with new key path
3. Test all team members can access with new keys
4. Update documentation with new security procedures

### 2. Suspicious Voting Activity

**Warning Signs:**
- Votes from unknown IP addresses
- Voting patterns outside normal work hours
- Rapid succession of vote initiations
- Failed authentication attempts in logs

**Investigation Process:**
```bash
# Check recent votes
tail -100 /var/log/quorumstop-votes.log

# Check authentication logs
sudo grep "authentication failure" /var/log/auth.log

# Check current connections
who
last -n 20

# Review AWS CloudTrail for API calls
aws logs filter-log-events \
    --log-group-name CloudTrail \
    --start-time $(date -d '1 hour ago' +%s)000
```

### 3. Security Group Breach

**If security group rules are modified without authorization:**

```bash
# 1. Document current state
aws ec2 describe-security-groups --group-ids sg-12345678 > security-group-backup.json

# 2. Remove unauthorized rules
aws ec2 revoke-security-group-ingress \
    --group-id sg-12345678 \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

# 3. Restore authorized rules only
aws ec2 authorize-security-group-ingress \
    --group-id sg-12345678 \
    --protocol tcp \
    --port 22 \
    --cidr 203.0.113.10/32

# 4. Enable additional logging
aws ec2 create-flow-logs \
    --resource-type Instance \
    --resource-ids i-1234567890abcdef0 \
    --traffic-type ALL \
    --log-destination-type cloud-watch-logs
```

## 🔐 Advanced Security Options

### 1. AWS Systems Manager Session Manager

**Benefits over SSH:**
- No inbound security group rules required
- All sessions logged to CloudTrail
- Centralized access control via IAM
- No SSH keys to manage
- Session recording capabilities

**Setup:**
```bash
# Install SSM agent on EC2 instance
sudo snap install amazon-ssm-agent --classic

# Create IAM role for EC2
aws iam create-role --role-name QuorumStop-EC2-Role --assume-role-policy-document file://trust-policy.json

# Attach SSM policy
aws iam attach-role-policy --role-name QuorumStop-EC2-Role --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
```

**Modified batch scripts:**
```batch
REM Replace SSH commands with SSM
aws ssm start-session --target %INSTANCE_ID%

REM For commands
aws ssm send-command ^
    --instance-ids %INSTANCE_ID% ^
    --document-name "AWS-RunShellScript" ^
    --parameters "commands=['/home/ubuntu/vote_shutdown.sh initiate %YOUR_IP%']"
```

### 2. Multi-Factor Authentication

**For AWS CLI:**
```batch
REM Configure MFA device
aws configure set aws_mfa_device arn:aws:iam::123456789012:mfa/alice

REM Get temporary credentials with MFA
aws sts get-session-token ^
    --serial-number arn:aws:iam::123456789012:mfa/alice ^
    --token-code 123456
```

### 3. Certificate-based Authentication

**SSH certificates instead of keys:**
```bash
# Generate SSH CA
ssh-keygen -t ed25519 -f ssh_ca

# Sign user key
ssh-keygen -s ssh_ca -I alice@company.com -n ubuntu ~/.ssh/alice_key.pub

# Configure server to trust CA
echo "TrustedUserCAKeys /etc/ssh/ssh_ca.pub" | sudo tee -a /etc/ssh/sshd_config
```

## 📋 Security Compliance

### SOC 2 / ISO 27001 Considerations

**Access Control:**
- Implement role-based access control
- Regular access reviews
- Principle of least privilege
- Multi-factor authentication

**Data Protection:**
- Encrypt data in transit (SSH/TLS)
- Secure key management
- Data retention policies
- Secure disposal of vote data

**Monitoring:**
- Comprehensive logging
- Real-time alerting
- Incident response procedures
- Regular security assessments

### GDPR Considerations

**If processing EU personal data:**
- Minimize data collection (only IPs needed for functionality)
- Implement data retention policies
- Provide data deletion capabilities
- Document data processing activities

## 🆘 Getting Security Help

**Report Security Vulnerabilities:**
- Email: security@[your-domain].com (if available)
- Create private security advisory on GitHub
- Do NOT open public issues for security vulnerabilities

**Security Questions:**
- 📖 [Security Wiki](https://github.com/yourusername/aws-ec2-quorumstop/wiki/Security)
- 💬 [Security Discussions](https://github.com/yourusername/aws-ec2-quorumstop/discussions/categories/security)
- 🔒 Private team channels for sensitive topics

---

**Remember:** Security is not a one-time setup but an ongoing process. Regular reviews, updates, and team training are essential for maintaining a secure collaborative environment.

**Next:** [Configuration Guide →](CONFIGURATION.md)