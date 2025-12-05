#!/bin/bash
# PM2 Setup Script for Bepo Discord Bot
# Run this once to set up PM2 with launchd for boot persistence

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BEPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Bepo PM2 Setup Script${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Change to project root
cd "$BEPO_ROOT"

# Step 1: Check if PM2 is installed globally
echo -e "${YELLOW}Step 1: Checking PM2 installation...${NC}"
if ! command -v pm2 &> /dev/null; then
    echo -e "${YELLOW}PM2 not found. Installing globally...${NC}"
    npm install -g pm2
    echo -e "${GREEN}✓ PM2 installed${NC}"
else
    echo -e "${GREEN}✓ PM2 already installed ($(pm2 --version))${NC}"
fi

# Step 2: Install pm2-logrotate for log management
echo ""
echo -e "${YELLOW}Step 2: Setting up PM2 log rotation...${NC}"
pm2 install pm2-logrotate 2>/dev/null || true
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 14
pm2 set pm2-logrotate:compress true
pm2 set pm2-logrotate:dateFormat YYYY-MM-DD_HH-mm-ss
echo -e "${GREEN}✓ PM2 log rotation configured (10MB max, 14 days retention)${NC}"

# Step 3: Create PM2 log directory
echo ""
echo -e "${YELLOW}Step 3: Creating PM2 log directory...${NC}"
mkdir -p "$BEPO_ROOT/logs/pm2"
echo -e "${GREEN}✓ Log directory created: $BEPO_ROOT/logs/pm2${NC}"

# Step 4: Stop any existing tmux sessions (migration from old setup)
echo ""
echo -e "${YELLOW}Step 4: Cleaning up old tmux sessions...${NC}"
if tmux has-session -t bepo-session 2>/dev/null; then
    echo -e "${YELLOW}Found existing tmux session 'bepo-session'. Stopping...${NC}"
    # Try to gracefully stop first
    tmux send-keys -t bepo-session:bot C-c 2>/dev/null || true
    sleep 3
    tmux kill-session -t bepo-session 2>/dev/null || true
    echo -e "${GREEN}✓ Old tmux session stopped${NC}"
else
    echo -e "${GREEN}✓ No old tmux sessions found${NC}"
fi

# Step 5: Kill any remaining Bepo processes
echo ""
echo -e "${YELLOW}Step 5: Stopping any remaining Bepo processes...${NC}"
pkill -f "node.*src/bot.js" 2>/dev/null || true
pkill -f "node.*monitor-service.js" 2>/dev/null || true
pkill -f "node.*offline-response-system.js" 2>/dev/null || true
sleep 2
echo -e "${GREEN}✓ Old processes cleaned up${NC}"

# Step 6: Deploy Discord commands
echo ""
echo -e "${YELLOW}Step 6: Deploying Discord commands...${NC}"
npm run deploy
echo -e "${GREEN}✓ Discord commands deployed${NC}"

# Step 7: Start Bepo with PM2
echo ""
echo -e "${YELLOW}Step 7: Starting Bepo with PM2...${NC}"
pm2 start ecosystem.config.cjs
echo -e "${GREEN}✓ Bepo started with PM2${NC}"

# Step 8: Save PM2 process list
echo ""
echo -e "${YELLOW}Step 8: Saving PM2 process list...${NC}"
pm2 save
echo -e "${GREEN}✓ PM2 process list saved${NC}"

# Step 9: Setup launchd startup (macOS boot persistence)
echo ""
echo -e "${YELLOW}Step 9: Setting up launchd for boot persistence...${NC}"
echo ""
echo -e "${CYAN}Running: pm2 startup launchd${NC}"
echo -e "${YELLOW}If prompted, copy and run the sudo command shown below:${NC}"
echo ""
pm2 startup launchd

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${CYAN}Bepo is now running with PM2 and will:${NC}"
echo "  • Auto-restart on crashes (max 10 restarts)"
echo "  • Auto-start on system boot (via launchd)"
echo "  • Rotate logs automatically (14 days retention)"
echo "  • Ping healthchecks.io every 30 seconds"
echo ""
echo -e "${CYAN}Useful PM2 commands:${NC}"
echo "  pm2 status          - Show process status"
echo "  pm2 logs bepo-bot   - View live logs"
echo "  pm2 monit           - Real-time monitoring dashboard"
echo "  pm2 restart bepo-bot - Restart the bot"
echo "  pm2 stop bepo-bot   - Stop the bot"
echo ""
echo -e "${CYAN}Or use the simplified scripts:${NC}"
echo "  ./scripts/start-bepo.sh  - Start Bepo"
echo "  ./scripts/stop-bepo.sh   - Stop Bepo"
echo "  ./scripts/bepo-status.sh - Check status"
echo ""

# Show current status
echo -e "${CYAN}Current PM2 Status:${NC}"
pm2 status
