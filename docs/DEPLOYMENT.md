# Deployment Guide - Vehicle Selector Pro

## Fly.io Deployment (Recommended)

### Prerequisites
- Fly.io CLI installed
- Fly.io account created
- Application code ready

### 1. Install Fly.io CLI
```bash
# Using winget (Windows)
winget install Fly-io.flyctl

# Or download from https://fly.io/
```

### 2. Authenticate with Fly.io
```bash
fly auth login
```

### 3. Initialize Application
```bash
cd vehicle-selector-pro
fly launch --name vehicle-selector-pro
```

### 4. Configure Environment Variables
```bash
fly secrets set SHOPIFY_API_KEY=your_api_key
fly secrets set SHOPIFY_API_SECRET=your_api_secret
fly secrets set DATABASE_URL=postgres://user:password@hostname:5432/dbname
fly secrets set REDIS_URL=redis://hostname:6379/1
```

### 5. Deploy Application
```bash
fly deploy
```

### 6. Access Your Application
Your app will be available at: `https://vehicle-selector-pro.fly.dev`

## Database Setup

### Production Database
Fly.io provides managed PostgreSQL:
```bash
# Create PostgreSQL database
fly postgres create

# Attach to application
fly postgres attach vehicle-selector-pro-db
```

### Redis for Sidekiq
```bash
# Create Redis instance
fly redis create

# Attach to application
fly redis attach vehicle-selector-pro-redis
```

## Environment Configuration

### Production Environment Variables
Required variables for production:
- `SHOPIFY_API_KEY` - Shopify API key
- `SHOPIFY_API_SECRET` - Shopify API secret
- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_URL` - Redis connection string
- `RAILS_ENV` - Set to `production`
- `RAILS_SERVE_STATIC_FILES` - Set to `true`

### Security Considerations
- Never commit `.env` file to repository
- Use Fly.io secrets for sensitive data
- Rotate API keys regularly
- Enable SSL/TLS for all connections

## Scaling Configuration

### Basic Scaling
Update `fly.toml` for scaling:
```toml
[http_service]
  internal_port = 3000
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 1

[processes]
  app = "bundle exec puma -C config/puma.rb"
  worker = "bundle exec sidekiq -C config/sidekiq.yml"
```

### Monitor Performance
```bash
# View application logs
fly logs

# Monitor resource usage
fly dashboard
```

## Troubleshooting Deployment

### Common Issues

#### Build Failures
```bash
# Check build logs
fly logs --build

# Rebuild without cache
fly deploy --build-only
```

#### Database Connection Issues
```bash
# Check database status
fly postgres list

# Reset database connection
fly postgres reset vehicle-selector-pro-db
```

#### Runtime Errors
```bash
# View application logs
fly logs

# SSH into application
fly ssh
```

## Continuous Deployment

### GitHub Actions Integration
Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy to Fly.io
on:
  push:
    branches: [ main ]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: superfly/flyctl-actions/setup-flyctl@master
      - run: flyctl deploy --remote-only
```

## Monitoring and Maintenance

### Health Checks
The application includes a health check endpoint:
```bash
curl https://vehicle-selector-pro.fly.dev/up
```

### Log Management
```bash
# View recent logs
fly logs

# Follow logs in real-time
fly logs --tail
```

### Backup Strategy
- Regular database backups via Fly.io
- Export Shopify metafields periodically
- Keep configuration in version control

## Rollback Procedures

### Quick Rollback
```bash
# Rollback to previous deployment
fly deploy --rollback
```

### Database Rollback
```bash
# Use Fly.io database snapshots
fly postgres snapshots
```

## Performance Optimization

### Caching Strategy
- Enable Rails caching in production
- Use Redis for session storage
- Implement CDN for static assets

### Database Optimization
- Add database indexes for frequently queried fields
- Use connection pooling
- Enable query caching

## Security Best Practices

1. **Environment Variables**: Never commit secrets
2. **HTTPS Only**: Force SSL in production
3. **API Keys**: Rotate regularly
4. **Access Control**: Limit admin access
5. **Monitoring**: Set up alerts for suspicious activity

## Support and Maintenance

For deployment issues:
1. Check Fly.io status page
2. Review application logs
3. Consult Fly.io documentation
4. Check GitHub issues

## Alternative Deployment Platforms

### Railway
- Easy PostgreSQL and Redis setup
- GitHub integration
- Simple deployment process

### Render
- Free tier available
- Built-in PostgreSQL
- Automatic SSL certificates

### Heroku
- Mature platform
- Extensive documentation
- Good for scaling