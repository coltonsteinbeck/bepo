# Operations Guide

Quick reference for common operational tasks and troubleshooting.

## 🚀 Daily Operations

### Starting the Bot

```bash
# Production start with PM2
npm run pm2:start

# Development mode (direct, no PM2)
npm run dev

# First-time setup (PM2 + launchd)
./scripts/pm2-setup.sh
```

### Stopping the Bot

```bash
# Stop bot
npm run pm2:stop

# Stop and remove from PM2
pm2 delete bepo-bot
```

### Checking Status

```bash
# PM2 process status
npm run pm2:status
pm2 status

# PM2 dashboard (real-time)
pm2 monit

# Shell script status
./scripts/bepo-status.sh
```

## 📊 Monitoring & Logs

### External Monitoring (Healthchecks.io)

The bot pings Healthchecks.io every 30 seconds as a dead-man's switch:
- **Healthy**: Pings `/start` on startup, then pings every 30s
- **Unhealthy/Shutdown**: Pings `/fail` endpoint
- **Alerts**: Webhook notification to Discord if ping is missed

Check your Healthchecks.io dashboard for monitoring status.

### Viewing Logs

```bash
# PM2 live logs
pm2 logs bepo-bot
npm run pm2:logs

# PM2 log files location
ls logs/pm2/

# Search logs
grep "error" logs/pm2/bepo-bot-out.log
grep "error" logs/pm2/bepo-bot-error.log
```

### Log Management

Logs are automatically managed:
- **PM2 Log Rotation**: 10MB max file size, 14-day retention (via pm2-logrotate)
- **Health Logs**: Auto-cleanup of files older than 14 days (built into bot.js)
- **Critical Error Logs**: Auto-cleanup of files older than 14 days

## 🔧 Troubleshooting

### Bot is Not Responding

1. Check if bot is running:
   ```bash
   pm2 status
   ./scripts/bepo-status.sh
   ```

2. Check recent errors:
   ```bash
   pm2 logs bepo-bot --lines 100
   ```

3. View live logs:
   ```bash
   pm2 logs bepo-bot
   ```

4. Restart the bot:
   ```bash
   npm run pm2:restart
   pm2 restart bepo-bot
   ```

### High Error Rate

1. Check Healthchecks.io dashboard for ping failures

2. Search for specific errors:
   ```bash
   grep -i "Discord API\|rate limit\|timeout" logs/pm2/bepo-bot-error.log
   ```

3. Check PM2 metrics:
   ```bash
   pm2 monit
   ```

### Memory Issues

1. Check process status:
   ```bash
   pm2 describe bepo-bot
   ```

2. View memory usage:
   ```bash
   pm2 monit
   ```

3. Restart if needed (auto-restart at 500MB):
   ```bash
   pm2 restart bepo-bot
   ```

4. PM2 will auto-restart on crash (max 10 restarts with 5s delay)

### Service Won't Start

1. Check PM2 status:
   ```bash
   pm2 status
   pm2 describe bepo-bot
   ```

2. Kill stale processes:
   ```bash
   pm2 delete bepo-bot
   pkill -f "node.*src/bot.js"
   ```

3. Check environment:
   ```bash
   cat .env | grep -v "^#" | grep -v "^$"
   ```

4. Start fresh:
   ```bash
   npm run pm2:start
   ```

## 🧹 Maintenance

### Regular Maintenance (Weekly)

```bash
# 1. Check PM2 status and logs
pm2 status
pm2 logs bepo-bot --lines 50

# 2. Check Healthchecks.io dashboard for any missed pings

# 3. Review error logs
grep -i "critical\|error" logs/pm2/bepo-bot-error.log | tail -50
```

### Automatic Maintenance

The following are handled automatically:
- **Log Rotation**: PM2-logrotate (10MB max, 14 days retention)
- **Health Logs**: Cleaned up every 6 hours (14-day retention)
- **Auto-Restart**: PM2 restarts on crash (max 10, 5s delay)
- **Memory Limit**: PM2 restarts at 500MB
- **Boot Persistence**: launchd starts PM2 on system boot

### Before Deploying Changes

```bash
# 1. Run tests
npm test

# 2. Check status
pm2 status

# 3. Stop bot
pm2 stop bepo-bot

# 4. Deploy changes (git pull, etc.)

# 5. Install dependencies if package.json changed
npm install

# 6. Deploy commands if needed
npm run deploy

# 7. Start bot
pm2 start bepo-bot

# 8. Save PM2 state and monitor
pm2 save
pm2 logs bepo-bot
```

## 📈 Performance Monitoring

### Real-time Monitoring

```bash
# PM2 dashboard (CPU, memory, logs)
pm2 monit

# Live log monitoring
pm2 logs bepo-bot
```

### External Monitoring

- **Healthchecks.io Dashboard**: View ping history and uptime
- **Discord Webhook**: Receives alerts when bot goes down or shuts down

### Historical Analysis

```bash
# Search logs for patterns
grep -i "slow response\|timeout\|rate limit" logs/pm2/bepo-bot-*.log

# View PM2 restart history
pm2 describe bepo-bot | grep -A5 "restart"
```

## 🔐 Security

### Checking for Exposed Secrets

```bash
# Verify .env is not committed
git status

# Check for accidental secret commits
git log -p | grep -i "api_key\|token\|secret"
```

### Rotating Credentials

1. Update `.env` with new credentials
2. Restart bot: `npm run restart`
3. Verify: `npm run health:once`
4. Test commands in Discord

## 📊 Metrics & Analytics

### Current Status

```bash
# Single snapshot
npm run health:once

# Detailed report
npm run status:detailed
```

### Log Analysis

```bash
# Overall statistics
npm run logs:stats

# Error frequency
npm run logs:search "ERROR"

# Warning frequency
npm run logs:search "WARN"
```

## 🆘 Emergency Procedures

### Bot is Completely Down

```bash
# 1. Check Healthchecks.io - you should have received a Discord alert

# 2. Check PM2 status
pm2 status

# 3. If PM2 shows errored, check logs
pm2 logs bepo-bot --lines 100

# 4. Force restart if needed
pm2 delete bepo-bot
pkill -9 -f "node.*src/bot.js"

# 5. Start fresh
npm run pm2:start

# 6. Save state and monitor
pm2 save
pm2 logs bepo-bot
```

### Database Connection Issues

```bash
# 1. Check environment
echo $SUPABASE_URL
echo $SUPABASE_KEY

# 2. Test connection
npm run test:integration

# 3. Check logs
npm run logs:search "supabase\|database"
```

### Discord API Issues

```bash
# 1. Check Discord status
# Visit: https://discordstatus.com

# 2. Check rate limits
npm run logs:search "rate limit"

# 3. Verify token
# Visit: https://discord.com/developers/applications
```

## 📞 Getting Help

### Information to Gather

Before asking for help, collect:

```bash
# 1. System status
npm run status:detailed > status.txt

# 2. Recent errors
npm run logs:search "ERROR" > errors.txt

# 3. Log statistics
npm run logs:stats > stats.txt

# 4. Configuration (without secrets)
cat .env | sed 's/=.*/=***/' > config.txt
```

### Common Issues & Solutions

| Issue | Command | Solution |
|-------|---------|----------|
| Bot offline | `npm run health` | Check Discord status, verify token |
| High memory | `npm run cleanup` | Clean old logs, restart services |
| Slow responses | `npm run logs:stats` | Check for errors, restart |
| Commands not working | `npm run deploy` | Redeploy slash commands |
| Logs filling disk | `npm run logs:rotate` | Rotate and compress logs |

## 🎯 Quick Command Reference

```bash
# Start/Stop/Restart
npm start              # Start bot with PM2
npm stop               # Stop bot
npm restart            # Restart bot
npm run start:full     # Deploy commands + start + save
npm run restart:full   # Deploy commands + restart + save

# Development
npm run dev            # Run directly (no PM2)

# Status & Monitoring
npm run status         # Detailed status
npm run pm2:status     # PM2 process status
npm run pm2:monit      # Live dashboard

# Logs
npm run pm2:logs       # Live PM2 logs
npm run logs:bot       # Tail stdout log
npm run logs:error     # Tail error log

# First-Time Setup
npm run pm2:setup      # Install PM2 + launchd

# PM2 Utilities
npm run pm2:save       # Save process list
npm run pm2:delete     # Remove from PM2
```
