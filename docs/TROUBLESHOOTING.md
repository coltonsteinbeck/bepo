# Troubleshooting Guide

## Quick Diagnostics

### Check Bot Status
```bash
pm2 status              # PM2 process status
pm2 monit               # Real-time dashboard
./scripts/bepo-status.sh # Shell script status
```

### Check External Monitoring
- **Healthchecks.io Dashboard**: View ping history and missed pings
- **Discord Webhook**: Check for shutdown/crash notifications

### Common Issues

#### Bot Won't Start
1. **Check PM2 Status**
   ```bash
   pm2 status
   pm2 describe bepo-bot
   ```

2. **Check Environment Variables**
   ```bash
   # Verify required variables are set
   echo $DISCORD_TOKEN
   echo $SUPABASE_URL
   echo $SUPABASE_KEY
   echo $HEALTHCHECK_PING_URL
   ```

3. **Check Dependencies**
   ```bash
   npm install              # Reinstall dependencies
   node --version          # Ensure Node.js 18+
   ```

4. **Check PM2 Logs**
   ```bash
   pm2 logs bepo-bot --lines 100
   ```

#### Bot Goes Offline Unexpectedly

**Check Healthchecks.io:**
- Login to Healthchecks.io dashboard
- Check when last ping was received
- Review ping history for patterns

**Check PM2 Auto-Restart:**
```bash
pm2 describe bepo-bot | grep -A10 "status\|restart"
```
PM2 auto-restarts on crash (max 10 restarts with 5s delay)

**Memory Issues:**
- PM2 auto-restarts at 500MB memory limit
- Check: `pm2 monit`

**Database Connection:**
- Test connection: `node scripts/check-bot-status.js`
- Check Supabase status at status.supabase.com

**Rate Limiting:**
- Check Discord rate limit headers in logs
- Wait 10-15 minutes before restarting

#### Commands Not Working

**Slash Commands:**
1. Re-deploy commands: `node scripts/deploy-commands.js`
2. Check bot permissions in Discord server settings
3. Verify bot has "applications.commands" scope

**Memory Commands:**
- Check database connection
- Verify user permissions
- Clear expired memories: `/memory clear type:temporary`

#### Gaming Notifications Not Working

**CS2 Notifications:**
1. Verify webhook URL: `node scripts/verify-cs2-configuration.js`
2. Check channel permissions
3. Test manually: `node scripts/simulate-cs2-notification.js`

**Apex Notifications:**
1. Test setup: `node scripts/setup-apex-channel-and-test.js`
2. Check API limits
3. Verify webhook configuration

## Error Messages

### Database Errors
```
Error: connect ECONNREFUSED
```
**Solution:** Check Supabase connection and credentials

```
Error: password authentication failed
```
**Solution:** Verify SUPABASE_KEY environment variable

### Discord Errors
```
DiscordAPIError[50013]: Missing Permissions
```
**Solution:** Check bot role permissions in server settings

```
DiscordAPIError[50001]: Missing Access
```
**Solution:** Ensure bot is in the target channel/server

### Memory System Errors
```
Memory limit exceeded
```
**Solution:** Clear old memories or increase limits

```
Invalid context type
```
**Solution:** Use valid types: conversation, preference, summary, temporary

## Healthchecks.io Issues

### Pings Not Being Received
1. **Check Environment Variable**
   ```bash
   echo $HEALTHCHECK_PING_URL
   ```

2. **Test Ping Manually**
   ```bash
   curl -fsS --retry 3 $HEALTHCHECK_PING_URL
   ```

3. **Check Bot Logs**
   ```bash
   pm2 logs bepo-bot | grep -i "healthcheck\|ping"
   ```

### False Alerts
- Increase grace period in Healthchecks.io settings
- Default ping interval is 30 seconds
- Recommended grace period: 2-5 minutes

## Performance Issues

### High Memory Usage
1. **Check PM2 Memory Usage**
   ```bash
   pm2 monit
   pm2 describe bepo-bot | grep memory
   ```

2. **PM2 Auto-Restart**
   - Bot auto-restarts at 500MB memory limit
   - Check restart count: `pm2 describe bepo-bot`

3. **Manual Restart**
   ```bash
   pm2 restart bepo-bot
   ```

### Slow Response Times
1. **Check Database Performance**
   - Review Supabase dashboard
   - Check for slow queries

2. **Monitor API Limits**
   - Discord: 50 requests per second
   - OpenAI: Check usage dashboard

3. **Clear Old Data**
   ```bash
   node scripts/cleanup-old-data.js
   ```

## Development Issues

### Test Failures
1. **Unit Tests**
   ```bash
   npm test                 # Run all tests
   npm run test:unit        # Unit tests only
   ```

2. **Integration Tests**
   ```bash
   npm run test:integration
   ```

3. **Manual Testing**
   ```bash
   node test-error-handling.js
   ```

### Import/Export Errors
```bash
node debug-imports.js    # Check module resolution
```

## Monitoring Commands

### PM2 Commands
```bash
pm2 status              # Process status
pm2 monit               # Real-time dashboard
pm2 logs bepo-bot       # Live logs
pm2 describe bepo-bot   # Detailed info
pm2 restart bepo-bot    # Restart
```

### Health Check Commands
```bash
/health                  # Bot health status (Discord)
/debug-memory [user]     # Memory debugging (admin)
```

### Log Files
- `logs/pm2/bepo-bot-out.log` - Standard output
- `logs/pm2/bepo-bot-error.log` - Error output
- `logs/bot-status.json` - Current bot status
- `logs/health-YYYY-MM-DD.json` - Daily health logs (14-day retention)
- `logs/critical-errors-YYYY-MM-DD.json` - Error tracking (14-day retention)

## Getting Help

### Log Collection
Before reporting issues, collect:
1. Error messages from PM2 logs
2. PM2 status: `pm2 describe bepo-bot`
3. Healthchecks.io ping history
4. Environment: Node version, OS

### Debug Mode
Enable verbose logging:
```bash
DEBUG=bepo:* npm run dev
```

### Reset Everything
Complete reset:
```bash
npm run pm2:delete
pkill -f "node.*src/bot.js"
rm -rf logs/pm2/*
npm run start:full
```
