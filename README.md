# Bepo - Discord Bot

A feature-rich Discord bot with PM2 process management, Healthchecks.io monitoring, and game integration.

## Quick Start

```bash
# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your tokens and configuration
# Required: DISCORD_TOKEN, SUPABASE_URL, SUPABASE_KEY
# Required: HEALTHCHECK_PING_URL, DISCORD_ALERT_WEBHOOK

# First-time setup (installs PM2, configures launchd)
./scripts/pm2-setup.sh

# Check status
pm2 status
./scripts/bepo-status.sh
```

## 📚 Documentation

All documentation has been moved to the [`docs/`](./docs/) folder:

### Essential Guides

- **[Quick Discord Testing](./docs/DISCORD_TESTING_QUICK.md)** - Fast testing procedures
- **[User Guide](./docs/USER_GUIDE.md)** - Complete user documentation
- **[Technical Documentation](./docs/TECHNICAL_DOCS.md)** - Developer reference

### Setup & Configuration

- **[Complete Offline Solution](./docs/COMPLETE_OFFLINE_SOLUTION.md)** - Offline mode setup
- **[Offline Mode Testing](./docs/OFFLINE_MODE_TESTING.md)** - Comprehensive testing
- **[Implementation Summary](./docs/IMPLEMENTATION_SUMMARY.md)** - Architecture overview

### Testing & Troubleshooting

- **[Complete Test Scenarios](./docs/COMPLETE_TEST_SCENARIOS.md)** - All test cases
- **[Testing Guide](./docs/TESTING_GUIDE.md)** - Testing procedures
- **[Quick Reference](./docs/QUICK_REFERENCE.md)** - Command reference

### Game Integration

- **[Apex Integration](./docs/APEX_INTEGRATION_SUMMARY.md)** - Apex Legends features
- **[Enhanced Guide](./docs/BEPO_ENHANCED_GUIDE.md)** - Advanced features

### Recent Improvements

- **[Shutdown Reason Improvements](./docs/SHUTDOWN_REASON_IMPROVEMENTS.md)** - Enhanced status detection

## ⚡ Key Features

- **🤖 Discord Bot**: Slash commands, interactive embeds, and rich responses
- **📊 PM2 Process Management**: Auto-restart, memory limits, log rotation
- **🔔 External Monitoring**: Healthchecks.io dead-man's switch with Discord alerts
- **🔄 Boot Persistence**: launchd ensures bot starts on system boot
- **🎮 Game Integration**: Apex Legends and CS2 updates
- **📝 Automatic Log Cleanup**: 14-day retention for health and error logs

## 🚀 Architecture

| Component | Purpose |
|-----------|----------|
| PM2 | Process management, auto-restart, log rotation |
| Healthchecks.io | External monitoring (30s dead-man's switch) |
| launchd | Boot persistence (macOS) |
| Discord Webhook | Shutdown/crash notifications |

## 📋 Quick Commands

```bash
# Start/Stop/Restart
npm start                # Start bot with PM2
npm stop                 # Stop bot
npm restart              # Restart bot
npm run start:full       # Deploy + start + save state
npm run restart:full     # Deploy + restart + save state

# Development
npm run dev              # Run directly without PM2
npm test                 # Run tests
npm run deploy           # Deploy slash commands

# Status & Monitoring
npm run status           # Detailed status report
npm run pm2:status       # PM2 process status
npm run pm2:monit        # Real-time dashboard
npm run pm2:logs         # Live logs

# First-Time Setup
npm run pm2:setup        # Install PM2 + launchd
npm run pm2:save         # Save PM2 state
```

## 🔧 Architecture

- **Main Bot** (`src/bot.js`): Primary Discord bot process
- **Monitor** (`scripts/bot-monitor.js`): Health checking and alerting
- **Offline System** (`scripts/offline-response-system.js`): Backup response handling
- **Health Command**: Works both online (slash command) and offline (mention response)

## 📞 Support

For issues or questions, check the documentation in the `docs/` folder or contact the development team.

---

_Bepo - Your reliable Discord companion, online or offline._
