#!/bin/bash
# ============================================
# AWS EC2 QuorumStop - Server Installer
# Automated installation of voting system
# ============================================

set -e

echo "🚀 AWS EC2 QuorumStop - Server Installation"
echo "=================================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m' 
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

if [ "$EUID" -eq 0 ]; then
  print_error "Please run this script as a regular user (not root)"
  exit 1
fi

print_info "Starting installation process..."
echo ""

echo "🔍 Step 1: Checking prerequisites..."

if ! command -v apt >/dev/null 2>&1; then
  print_warning "This installer is designed for Ubuntu/Debian systems"
  print_info "For other systems, install manually following the README"
fi

if command -v wget >/dev/null 2>&1; then
  DOWNLOAD_CMD="wget -O"
  print_status "Found wget"
elif command -v curl >/dev/null 2>&1; then
  DOWNLOAD_CMD="curl -o"
  print_status "Found curl"
else
  print_error "Neither wget nor curl found. Please install one of them."
  exit 1
fi

if command -v wall >/dev/null 2>&1; then
  print_status "Wall command available"
else
  print_warning "Wall command not found - notifications may not work"
fi

echo ""

echo "📥 Step 2: Downloading vote script..."

SCRIPT_URL="https://raw.githubusercontent.com/Obad94/aws-ec2-quorumstop/main/server/vote_shutdown.sh"
SCRIPT_PATH="/home/$USER/vote_shutdown.sh"

if [ -f "$SCRIPT_PATH" ]; then
  print_warning "Existing script found at $SCRIPT_PATH"
  read -p "Do you want to overwrite it? (y/N): " -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Installation cancelled"
    exit 0
  fi
  rm -f "$SCRIPT_PATH"
fi

print_info "Downloading from: $SCRIPT_URL"
if $DOWNLOAD_CMD "$SCRIPT_PATH" "$SCRIPT_URL"; then
  print_status "Script downloaded successfully"
else
  print_error "Failed to download script"
  print_info "You can manually download from: $SCRIPT_URL"
  exit 1
fi

echo ""

echo "🔧 Step 3: Setting up permissions..."
chmod +x "$SCRIPT_PATH"
print_status "Made script executable"

if "$SCRIPT_PATH" help >/dev/null 2>&1; then
  print_status "Script is working correctly"
else
  print_error "Script test failed"
  exit 1
fi

echo ""

echo "🔗 Step 4: Creating system-wide command..."
read -p "Create system-wide 'vote_shutdown' command? (Y/n): " -r
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
  if sudo ln -sf "$SCRIPT_PATH" /usr/local/bin/vote_shutdown; then
    print_status "System-wide command created: vote_shutdown"
    print_info "You can now run 'vote_shutdown' from anywhere"
  else
    print_warning "Failed to create system-wide command"
    print_info "You can still use: $SCRIPT_PATH"
  fi
else
  print_info "Skipping system-wide command creation"
fi

echo ""

echo "👥 Step 5: Team configuration..."
print_info "Configure team member IP addresses and names in the script (DEV_NAMES)"
read -p "Do you want to configure team members now? (y/N): " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
  if command -v nano >/dev/null 2>&1; then
    nano "$SCRIPT_PATH"
  else
    vi "$SCRIPT_PATH"
  fi
else
  print_info "You can configure team members later by editing: $SCRIPT_PATH"
fi

echo ""

echo "🧪 Step 6: Testing installation..."
print_info "Running system diagnostics..."
"$SCRIPT_PATH" debug

echo ""
print_status "🎉 AWS EC2 QuorumStop server installation complete!"
print_info "The server is now ready for democratic voting"
echo ""

if command -v vote_shutdown >/dev/null 2>&1; then
  print_info "✨ Try running: vote_shutdown help"
else
  print_info "✨ Try running: $SCRIPT_PATH help"
fi
