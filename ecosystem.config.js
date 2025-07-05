module.exports = {
  apps: [
    {
      name: 'topping-backend',
      script: './backend/dist/index.js',
      cwd: '/home/toppingapp/topping-frozen-app',
      env: {
        NODE_ENV: 'production',
        PORT: 3001
      },
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      error_file: './logs/backend-error.log',
      out_file: './logs/backend-out.log',
      log_file: './logs/backend-combined.log',
      time: true,
      // Configuración adicional para producción
      kill_timeout: 5000,
      listen_timeout: 3000,
      restart_delay: 4000,
      max_restarts: 10,
      min_uptime: '10s'
    }
  ],

  deploy: {
    production: {
      user: 'toppingapp',
      host: 'TU_IP_DEL_VPS',
      ref: 'origin/main',
      repo: 'https://github.com/jecaicedo27/topping-frozen-app.git',
      path: '/home/toppingapp/topping-frozen-app',
      'pre-deploy-local': '',
      'post-deploy': 'cd backend && npm install && npm run build && cd .. && npm install && npm run build:frontend && pm2 reload ecosystem.config.js --env production',
      'pre-setup': ''
    }
  }
};
