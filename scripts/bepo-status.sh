#!/bin/bash
# Bepo System Status Checker (PM2 version)
# Provides detailed status information about Bepo

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/bepo-config.sh" 2>/dev/null || {
    echo "ERROR: Could not load bepo-config.sh"
    exit 1
}

# Ensure we're in the project root
cd "$BEPO_ROOT" || {
    echo "ERROR: Could not change to project root: $BEPO_ROOT"
    exit 1
}

# Parse arguments
QUIET_MODE=false
DETAILED_MODE=false

for arg in "$@"; do
    case $arg in
        -q|--quiet)
            QUIET_MODE=true
            shift
            ;;
        -d|--detailed)
            DETAILED_MODE=true
            shift
            ;;
    esac
done

if [ "$QUIET_MODE" = "false" ]; then
    echo -e "${COLOR_CYAN}========================================${COLOR_NC}"
    echo -e "${COLOR_CYAN}  Bepo Status Report${COLOR_NC}"
    echo -e "${COLOR_CYAN}========================================${COLOR_NC}"
    echo ""
fi

# Check PM2 status
if command -v pm2 &> /dev/null; then
    if pm2 describe $PM2_APP_NAME &> /dev/null; then
        # Get PM2 process info
        pm2_info=$(pm2 jlist 2>/dev/null | python3 -c "import sys, json; data = json.load(sys.stdin); app = next((a for a in data if a['name'] == '$PM2_APP_NAME'), None); print(json.dumps(app))" 2>/dev/null || echo "{}")
        
        status=$(echo "$pm2_info" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('pm2_env', {}).get('status', 'unknown'))" 2>/dev/null || echo "unknown")
        pid=$(echo "$pm2_info" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('pid', 0))" 2>/dev/null || echo "0")
        memory=$(echo "$pm2_info" | python3 -c "import sys, json; data = json.load(sys.stdin); m = data.get('monit', {}).get('memory', 0); print(f'{m / 1024 / 1024:.1f}')" 2>/dev/null || echo "0")
        cpu=$(echo "$pm2_info" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('monit', {}).get('cpu', 0))" 2>/dev/null || echo "0")
        restarts=$(echo "$pm2_info" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('pm2_env', {}).get('restart_time', 0))" 2>/dev/null || echo "0")
        uptime=$(echo "$pm2_info" | python3 -c "import sys, json; data = json.load(sys.stdin); u = data.get('pm2_env', {}).get('pm_uptime', 0); import time; diff = int((time.time() * 1000 - u) / 1000); h = diff // 3600; m = (diff % 3600) // 60; print(f'{h}h {m}m')" 2>/dev/null || echo "0h 0m")

        if [ "$status" = "online" ]; then
            print_status $COLOR_GREEN "🟢 Bepo is ONLINE"
        else
            print_status $COLOR_RED "🔴 Bepo is $status"
        fi
        
        echo ""
        print_status $COLOR_CYAN "PM2 Process Info:"
        echo "  Status:    $status"
        echo "  PID:       $pid"
        echo "  Memory:    ${memory} MB"
        echo "  CPU:       ${cpu}%"
        echo "  Uptime:    $uptime"
        echo "  Restarts:  $restarts"
    else
        print_status $COLOR_RED "🔴 Bepo is not registered with PM2"
        print_status $COLOR_YELLOW "Run ./scripts/start-bepo.sh to start"
    fi
else
    print_status $COLOR_YELLOW "⚠️  PM2 not installed"
    
    # Fallback to pgrep
    BOT_PIDS=$(pgrep -f "$BOT_PROCESS_PATTERN" 2>/dev/null || true)
    if [ -n "$BOT_PIDS" ]; then
        print_status $COLOR_GREEN "🟢 Bot process running (PID: $BOT_PIDS)"
    else
        print_status $COLOR_RED "🔴 Bot process not found"
    fi
fi

# Check bot-status.json for additional info
echo ""
print_status $COLOR_CYAN "Bot Health Status:"
if [ -f "$BEPO_STATUS_FILE" ]; then
    discord_connected=$(cat "$BEPO_STATUS_FILE" | python3 -c "import sys, json; data = json.load(sys.stdin); print('Yes' if data.get('discord', {}).get('connected', False) else 'No')" 2>/dev/null || echo "Unknown")
    discord_ping=$(cat "$BEPO_STATUS_FILE" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('discord', {}).get('ping', 'N/A'))" 2>/dev/null || echo "N/A")
    guilds=$(cat "$BEPO_STATUS_FILE" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('discord', {}).get('guilds', 0))" 2>/dev/null || echo "0")
    error_count=$(cat "$BEPO_STATUS_FILE" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('health', {}).get('errorCount', 0))" 2>/dev/null || echo "0")
    last_updated=$(cat "$BEPO_STATUS_FILE" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('lastUpdated', 'Unknown'))" 2>/dev/null || echo "Unknown")
    
    echo "  Discord:   $discord_connected (ping: ${discord_ping}ms)"
    echo "  Guilds:    $guilds"
    echo "  Errors:    $error_count"
    echo "  Updated:   $last_updated"
else
    print_status $COLOR_YELLOW "  Status file not found"
fi

# Show Healthchecks.io status reminder
echo ""
print_status $COLOR_CYAN "External Monitoring:"
echo "  Healthchecks.io: Check your dashboard for ping status"
echo "  Interval: Every 30 seconds"

if [ "$DETAILED_MODE" = "true" ]; then
    echo ""
    print_status $COLOR_CYAN "Recent Logs (last 10 lines):"
    if [ -f "$BEPO_BOT_LOG" ]; then
        tail -10 "$BEPO_BOT_LOG" 2>/dev/null || echo "  Could not read log file"
    else
        echo "  Log file not found: $BEPO_BOT_LOG"
    fi
fi

if [ "$QUIET_MODE" = "false" ]; then
    echo ""
    print_status $COLOR_CYAN "Commands:"
    echo "  pm2 logs $PM2_APP_NAME   - View live logs"
    echo "  pm2 monit                - Real-time monitoring"
    echo "  ./scripts/start-bepo.sh - Start bot"
    echo "  ./scripts/stop-bepo.sh  - Stop bot"
fi
