// PM2 Ecosystem Configuration for Bepo Discord Bot
// https://pm2.keymetrics.io/docs/usage/application-declaration/

module.exports = {
  apps: [
    {
      name: 'bepo-bot',
      script: 'src/bot.js',
      cwd: '/Users/crmsserver/dev/bepo',
      
      // Node.js options
      node_args: '--no-deprecation',
      
      // Restart behavior
      autorestart: true,
      watch: false,
      max_restarts: 10,
      min_uptime: '10s',
      restart_delay: 5000, // 5 seconds between restarts
      
      // Crash recovery - exponential backoff
      exp_backoff_restart_delay: 1000, // Start with 1s, doubles each restart
      
      // Memory management
      max_memory_restart: '500M',
      
      // Logging
      error_file: 'logs/pm2/bepo-error.log',
      out_file: 'logs/pm2/bepo-out.log',
      log_file: 'logs/pm2/bepo-combined.log',
      time: true, // Add timestamps to logs
      merge_logs: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      
      // Environment
      env: {
        NODE_ENV: 'production'
      },
      
      // Graceful shutdown - PM2 will send SIGINT first, wait kill_timeout, then SIGKILL
      kill_timeout: 15000, // 15 seconds for graceful shutdown
      listen_timeout: 10000,
      wait_ready: false, // Don't wait for process.send('ready')
      
      // Instance management (single instance for Discord bot)
      instances: 1,
      exec_mode: 'fork'
    }
  ],
  
  // Deployment configuration (optional - for future use)
  deploy: {
    production: {
      user: 'crmsserver',
      host: 'localhost',
      ref: 'origin/main',
      repo: 'git@github.com:coltonsteinbeck1/bepo.git',
      path: '/Users/crmsserver/dev/bepo',
      'post-deploy': 'npm install && pm2 reload ecosystem.config.cjs --env production'
    }
  }
};
