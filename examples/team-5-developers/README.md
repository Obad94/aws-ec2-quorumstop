# Team of 5 Developers Example

This folder shows a sample `config.bat` for a 5‑developer team.

Adjustments you should make after copying lines into `scripts\config.bat`:
1. Replace INSTANCE_ID with your real EC2 instance ID.
2. Replace KEY_FILE with the actual path to your private key (.pem).
3. Replace DEV*_IP values with real public IPs (from whatismyipaddress.com).
4. Set YOUR_NAME and YOUR_IP for each developer’s local copy.
5. Remove any unused DEV* entries.

Extend beyond 5 developers:
- Add `set DEV6_IP=...`, `set DEV7_IP=...` etc. Scripts now enumerate DEV pattern variables dynamically.

Security note:
Use only placeholder/test IP ranges in committed examples (203.0.113.x, 198.51.100.x, 192.0.2.x). Never commit real IPs or secrets.
