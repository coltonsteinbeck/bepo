#!/bin/bash
# Start Bepo Discord Bot using PM2
# Usage: ./start-bepo.sh [--quick]
#   --quick: Skip deploying Discord commands (faster startup)

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/bepo-config.sh"

# Parse arguments
QUICK_MODE=false
for arg in "$@"; do
    case $arg in
        -q|--quick)
            QUICK_MODE=true
            shift
            ;;
    esac
done

# Ensure we're in the project root
cd "$BEPO_ROOT" || {
    echo "ERROR: Could not change to project root: $BEPO_ROOT"
    exit 1
}

# Setup log directories
setup_log_directories

echo -e "${COLOR_CYAN}========================================${COLOR_NC}"
echo -e "${COLOR_CYAN}  Starting Bepo Discord Bot${COLOR_NC}"
echo -e "${COLOR_CYAN}========================================${COLOR_NC}"
echo ""

# Check if PM2 is installed
if ! command -v pm2 &> /dev/null; then
    print_status $COLOR_RED "PM2 is not installed. Run: npm install -g pm2"
    print_status $COLOR_YELLOW "Or run ./scripts/pm2-setup.sh for full setup"
    exit 1
fi

# Check if already running
if pm2 describe $PM2_APP_NAME &> /dev/null; then
    pm2_status=$(pm2 jlist 2>/dev/null | grep -o "\"status\":\"[^\"]*\"" | head -1 | cut -d'"' -f4)
    if [ "$pm2_status" = "online" ]; then
        print_status $COLOR_YELLOW "Bepo is already running!"
        echo ""
        pm2 status $PM2_APP_NAME
        echo ""
        print_status $COLOR_CYAN "To restart: pm2 restart $PM2_APP_NAME"
        print_status $COLOR_CYAN "To view logs: pm2 logs $PM2_APP_NAME"
        exit 0
    fi
fi

# Deploy Discord commands (unless --quick)
if [ "$QUICK_MODE" = "false" ]; then
    print_status $COLOR_YELLOW "Step 1: Deploying Discord commands..."
    npm run deploy
    if [ $? -ne 0 ]; then
        print_status $COLOR_RED "Failed to deploy commands, but continuing..."
    fi
    echo ""
    print_status $COLOR_YELLOW "Step 2: Starting Bepo with PM2..."
else
    print_status $COLOR_YELLOW "Quick mode: Skipping command deployment"
    print_status $COLOR_YELLOW "Starting Bepo with PM2..."
fi
if pm2 describe $PM2_APP_NAME &> /dev/null; then
    # App exists in PM2, just restart it
    pm2 restart $PM2_APP_NAME
else
    # First time, start from ecosystem config
    pm2 start ecosystem.config.cjs
fi

# Save PM2 state
pm2 save --force

echo ""
print_status $COLOR_GREEN "========================================${COLOR_NC}"
print_status $COLOR_GREEN "  Bepo Started Successfully!${COLOR_NC}"
print_status $COLOR_GREEN "========================================${COLOR_NC}"
echo ""
print_status $COLOR_CYAN "Process Status:"
pm2 status $PM2_APP_NAME

echo ""
print_status $COLOR_CYAN "Useful commands:"
echo "  pm2 logs $PM2_APP_NAME    - View live logs"
echo "  pm2 monit                 - Real-time monitoring"
echo "  pm2 restart $PM2_APP_NAME - Restart the bot"
echo "  ./scripts/stop-bepo.sh   - Stop the bot"
echo "  ./scripts/bepo-status.sh - Detailed status"
echo ""
print_status $COLOR_CYAN "Features enabled:"
echo "  ✓ Auto-restart on crash (max 10 restarts)"
echo "  ✓ Healthchecks.io monitoring (30s interval)"
echo "  ✓ PM2 log rotation (14 days retention)"
echo "  ✓ Graceful shutdown with webhook notification"
