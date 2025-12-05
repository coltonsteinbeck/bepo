# Bepo Testing Guide

## Complete Test Checklist

### Prerequisites
- Ensure Discord bot token is configured
- Make sure all dependencies are installed: `npm install`
- Verify PM2 is installed: `pm2 --version`
- Verify Healthchecks.io URL is configured: `echo $HEALTHCHECK_PING_URL`

## Core System Tests

### 1. PM2 Setup Test
```bash
# First-time setup (if not already done)
./scripts/pm2-setup.sh

# Expected:
# - PM2 installed globally
# - pm2-logrotate configured (10MB, 14 days)
# - Bot started with PM2
# - launchd configured for boot persistence

# Check PM2 status
pm2 status

# Expected: bepo-bot showing as 'online'
```

### 2. PM2 Process Management Test
```bash
# Start bot
npm start

# Check status
npm run pm2:status
npm run status

# View logs
npm run pm2:logs

# Restart
npm restart

# Stop
npm stop

# Start with deploy
npm run start:full
```

### 3. Shell Script Test
```bash
# Test shell scripts
./scripts/bepo-status.sh   # Check status
./scripts/start-bepo.sh    # Start via shell
./scripts/stop-bepo.sh     # Stop via shell
```

## Gaming Integration Tests

### 1. APEX Command Test
In Discord, test these commands:
```
/apexnotify status                        # Check monitoring status
/apexnotify setchannel #your-test-channel # Set notification channel
/apexnotify start                         # Start monitoring
/maprotation                              # Test map rotation command
```

### 2. CS2 Command Test
```
/cs2                                      # Test CS2 updates
/cs2prices <skin_name>                    # Test skin price lookup
```

## Monitoring Tests

### 1. Healthchecks.io Integration Test
```bash
# Start bot
npm run pm2:start

# Check Healthchecks.io dashboard
# Expected: Pings received every 30 seconds

# Stop bot gracefully
pm2 stop bepo-bot

# Check Healthchecks.io dashboard
# Expected: /fail ping received, status changes to DOWN

# Check Discord webhook channel
# Expected: Orange embed notification about shutdown
```

### 2. Auto-Restart Test
```bash
# Start bot
npm run pm2:start

# Simulate crash
pm2 describe bepo-bot | grep restart
# Note the restart count

# Kill the process forcefully
pkill -9 -f "node.*src/bot.js"

# Wait a few seconds and check
pm2 status

# Expected: Bot restarted automatically, restart count increased
pm2 describe bepo-bot | grep restart
```

### 3. Memory Limit Test
```bash
# Check current memory usage
pm2 monit

# PM2 will auto-restart at 500MB (configured in ecosystem.config.cjs)
# Check logs for memory-related restarts:
grep -i "memory" logs/pm2/bepo-bot-*.log
```

### 4. Log File Tests
```bash
# Start system
npm run pm2:start

# Check PM2 log files
ls -la logs/pm2/
tail -f logs/pm2/bepo-bot-out.log
tail -f logs/pm2/bepo-bot-error.log

# Check health log files (auto-cleaned after 14 days)
ls -la logs/health-*.json
ls -la logs/critical-errors-*.json
```

### 5. Status File Tests
```bash
# Check status files are being updated
cat logs/bot-status.json

# Expected: JSON with current bot status and timestamps
```

### 6. Boot Persistence Test
```bash
# Verify launchd is configured
pm2 startup

# Save current state
pm2 save

# Reboot system and verify bot starts automatically
# (manual test - reboot your machine)
```

## Unit Testing

### Run Test Suite
```bash
# Run all tests
npm test

# Run specific test suites
npm run test:unit                         # Unit tests only
npm run test:integration                  # Integration tests only

# Run tests with coverage
npm run test:coverage
```

### Test Coverage Areas
- Memory utilities (memoryUtils.js)
- Apex utilities (apexUtils.js)
- CS2 utilities (cs2Utils.js)
- Command loading and validation
- Error handling functions
- Bot initialization

## Troubleshooting Tests

### 1. Process Management Test
```bash
# Check PM2 is managing the bot
pm2 status

# Start bot
npm run pm2:start

# Verify process is running
pm2 describe bepo-bot
ps aux | grep "node.*src/bot.js"

# Stop bot
npm run pm2:stop

# Verify process stopped
pm2 status
ps aux | grep "node.*src/bot.js"
```

### 2. Recovery Test
```bash
# Start bot
npm run pm2:start

# Kill process manually (simulating crash)
pkill -9 -f "node.*src/bot.js"

# Wait 5 seconds for PM2 auto-restart
sleep 5

# Verify PM2 restarted the bot
pm2 status

# Check restart count increased
pm2 describe bepo-bot | grep restart
```

### 3. Error Handling Test
```bash
# Test with invalid configuration
# (Temporarily rename .env file)
mv .env .env.backup

# Try to start
npm start

# Expected: Graceful error messages, no hanging processes

# Restore configuration
mv .env.backup .env
```

## Success Criteria

### PM2 Management Working
- `npm run pm2:start` starts bot via PM2
- `pm2 status` shows bot as 'online'
- `pm2 logs bepo-bot` shows live logs
- Bot auto-restarts on crash (max 10, 5s delay)
- Bot restarts at 500MB memory limit

### Healthchecks.io Working
- Pings received every 30 seconds
- `/fail` ping on graceful shutdown
- Discord webhook receives alerts

### Gaming Integration Working
- /apexnotify commands work properly
- Can set notification channel
- Can start/stop monitoring
- /maprotation shows current maps
- /cs2 and /cs2prices work correctly

### Boot Persistence Working
- launchd configured via `pm2 startup`
- PM2 state saved via `pm2 save`
- Bot starts automatically on system boot

### Integration Working
- All npm scripts work correctly
- Shell scripts integrate with PM2
- Logs are properly separated (stdout/stderr)
- 14-day log retention working

## Common Issues & Solutions

### Issue: PM2 not found
```bash
# Solution: Install PM2 globally
npm install -g pm2
```

### Issue: Bot not auto-restarting
```bash
# Solution: Check PM2 config
pm2 describe bepo-bot | grep -A5 restart
# Verify max_restarts not exceeded
pm2 reset bepo-bot  # Reset restart counter
```

### Issue: Processes not stopping cleanly
```bash
# Solution: Force kill all
pm2 delete bepo-bot
pkill -f "node.*src/bot.js"
```

### Issue: Discord token errors
```bash
# Solution: Check .env file
cat .env | grep BOT_TOKEN
# Ensure token is valid and has proper permissions
```

### Issue: Healthchecks.io not receiving pings
```bash
# Solution: Check environment variable
echo $HEALTHCHECK_PING_URL
# Test manually
curl -fsS $HEALTHCHECK_PING_URL
```

### Issue: Tests failing
```bash
# Solution: Check test environment
npm install                               # Reinstall dependencies
npm run test:unit                         # Run unit tests only
```

For additional troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

---

## ✅ Success Criteria

### PM2 Management Working
- [✅] `npm run pm2:start` starts bot via PM2
- [✅] `pm2 status` shows bot as 'online'
- [✅] `pm2 logs bepo-bot` shows live logs
- [✅] Bot auto-restarts on crash

### Healthchecks.io Working
- [✅] Pings received every 30 seconds
- [✅] `/fail` ping on graceful shutdown
- [✅] Discord webhook receives alerts

### APEX Mode Working
- [✅] `/apexnotify` commands work properly
- [✅] Can set notification channel
- [✅] Can start/stop monitoring
- [✅] `/maprotation` shows current maps

### Boot Persistence Working
- [✅] launchd configured via `pm2 startup`
- [✅] PM2 state saved via `pm2 save`
- [✅] Bot starts automatically on system boot

### Integration Working
- [✅] All npm scripts work correctly
- [✅] Shell scripts integrate with PM2
- [✅] Logs properly separated (stdout/stderr)
- [✅] 14-day log retention working

---

## 🚨 Known Issues & Solutions

### Issue: PM2 not found
```bash
# Solution: Run setup script
./scripts/pm2-setup.sh
```

### Issue: Processes not stopping cleanly
```bash
# Solution: Force kill all
pm2 delete bepo-bot
pkill -f "node.*src/bot.js"
```

### Issue: Discord token errors
```bash
# Solution: Check .env file
cat .env | grep BOT_TOKEN
# Ensure token is valid and has proper permissions
```

### Issue: Healthchecks.io not receiving pings
```bash
# Solution: Check environment variable
echo $HEALTHCHECK_PING_URL
curl -fsS $HEALTHCHECK_PING_URL
```

---

*All tests passed? Your Bepo setup is ready for production! 🎉*
