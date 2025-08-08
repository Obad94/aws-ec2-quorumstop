#!/bin/bash
# ============================================
# EC2 Democratic Shutdown - Server Installer
# Automated installation of voting system
# ============================================

set -e  # Exit on any error

echo "🚀 EC2 Democratic Shutdown - Server Installation"
echo "=================================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m' 
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please run this script as a regular user (not root)"
    exit 1
fi

print_info "Starting installation process..."
echo ""

# Step 1: Check prerequisites
echo "🔍 Step 1: Checking prerequisites..."

# Check if we're on Ubuntu/Debian
if ! command -v apt >/dev/null 2>&1; then
    print_warning "This installer is designed for Ubuntu/Debian systems"
    print_info "For other systems, install manually following the README"
fi

# Check if we have wget or curl
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

# Check if wall command exists
if command -v wall >/dev/null 2>&1; then
    print_status "Wall command available"
else
    print_warning "Wall command not found - notifications may not work"
fi

echo ""

# Step 2: Download vote script
echo "📥 Step 2: Downloading vote script..."

SCRIPT_URL="https://raw.githubusercontent.com/yourusername/ec2-democratic-shutdown/main/server/vote_shutdown.sh"
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

# Step 3: Set permissions
echo "🔧 Step 3: Setting up permissions..."

chmod +x "$SCRIPT_PATH"
print_status "Made script executable"

# Check if script works
if "$SCRIPT_PATH" help >/dev/null 2>&1; then
    print_status "Script is working correctly"
else
    print_error "Script test failed"
    exit 1
fi

echo ""

# Step 4: Create system-wide symlink (optional)
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

# Step 5: Team configuration
echo "👥 Step 5: Team configuration..."

print_info "You need to configure your team member IP addresses and names"
print_info "The script will work with default settings, but team names will show as 'Unknown'"
echo ""

read -p "Do you want to configure team members now? (y/N): " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Opening script editor..."
    print_info "Find the 'DEV_NAMES' section and update with your team's IPs and names"
    echo ""
    print_info "Example:"
    echo 'DEV_NAMES["203.0.113.10"]="Alice"'
    echo 'DEV_NAMES["203.0.113.20"]="Bob"'
    echo ""
    read -p "Press Enter to open editor..."
    
    # Try to use nano, fall back to vi
    if command -v nano >/dev/null 2>&1; then
        nano "$SCRIPT_PATH"
    else
        vi "$SCRIPT_PATH"
    fi
else
    print_info "You can configure team members later by editing: $SCRIPT_PATH"
fi

echo ""

# Step 6: Test installation
echo "🧪 Step 6: Testing installation..."

print_info "Running system diagnostics..."
"$SCRIPT_PATH" debug

echo ""
print_status "Installation completed successfully!"
echo ""

# Final instructions
echo "📋 Next Steps:"
echo "=============="
print_info "1. Configure team IPs in $SCRIPT_PATH (if not done already)"
print_info "2. Test voting: vote_shutdown help"
print_info "3. Run diagnostics: vote_shutdown debug" 
print_info "4. Set up your Windows clients with the batch scripts"
print_info "5. Test full system: Run shutdown_server.bat from Windows"
echo ""

echo "📖 Usage Examples:"
echo "=================="
echo "  vote_shutdown yes      # Vote to agree with shutdown"
echo "  vote_shutdown no       # Vote to reject shutdown"
echo "  vote_shutdown status   # Check current voting session"
echo "  vote_shutdown debug    # Show connection diagnostics"
echo "  vote_shutdown help     # Show all available commands"
echo ""

echo "🔧 Configuration File:"
echo "======================"
echo "  Location: $SCRIPT_PATH"
echo "  Edit with: nano $SCRIPT_PATH"
echo "  Look for: declare -A DEV_NAMES"
echo ""

echo "📚 Documentation:"
echo "=================="
echo "  Main README: https://github.com/yourusername/ec2-democratic-shutdown"
echo "  Installation Guide: docs/INSTALLATION.md"
echo "  Usage Guide: docs/USAGE.md"
echo "  Troubleshooting: docs/TROUBLESHOOTING.md"
echo ""

print_status "🎉 EC2 Democratic Shutdown server installation complete!"
print_info "The server is now ready for democratic voting"
echo ""

# Test if symlink was created successfully
if command -v vote_shutdown >/dev/null 2>&1; then
    print_info "✨ Try running: vote_shutdown help"
else
    print_info "✨ Try running: $SCRIPT_PATH help"
fi