# Setup Guide - Vehicle Selector Pro

## Prerequisites

### Required Software
- **Ruby**: 3.2.0 or newer
- **Rails**: 7.1.x+
- **Database**: SQLite3 (development) or PostgreSQL (production)
- **Redis**: 5.0+ (for Sidekiq and caching)

### Optional Software
- **Node.js**: For Theme App Extension development
- **Git**: For version control
- **PostgreSQL**: For production database

## Installation Steps

### 1. Clone the Repository
```bash
git clone https://github.com/your-org/vehicle-selector-pro.git
cd vehicle-selector-pro
```

### 2. Install Ruby Dependencies
```bash
bundle install
```

### 3. Setup Database
```bash
# Create database
bundle exec rake db:create

# Run migrations
bundle exec rake db:migrate

# Seed demo data
bundle exec rake db:seed
```

### 4. Configure Environment Variables
Create a `.env` file in the project root:
```env
SHOPIFY_API_KEY=your_shopify_api_key
SHOPIFY_API_SECRET=your_shopify_api_secret
SHOPIFY_STORE_DOMAIN=your-store.myshopify.com
HOST=https://your-app-url.com
REDIS_URL=redis://localhost:6379/1
```

### 5. Start Local Development Servers

#### Rails Server
```bash
bundle exec puma -C config/puma.rb
```

#### Sidekiq (Background Jobs)
```bash
bundle exec sidekiq -C config/sidekiq.yml
```

## Development Workflow

### Running Tests
```bash
ruby spec/test_runner.rb
```

### Accessing the Application
- **Admin Dashboard**: http://localhost:3000
- **App Proxy Endpoints**: http://localhost:3000/apps/vehicle-selector/*

## Troubleshooting

### Database Issues
```bash
# Reset database
bundle exec rake db:reset
bundle exec rake db:seed
```

### Redis Connection Issues
```bash
# Check Redis status
redis-cli ping

# Start Redis server
redis-server
```

### Gem Installation Issues
```bash
# Update bundler
gem install bundler
bundle install
```

## Shopify Partner Setup

### 1. Create Partner Account
1. Go to https://partners.shopify.com/
2. Sign up for free Partner account
3. Create a new App

### 2. Configure App
1. Add App URL (use ngrok for local development)
2. Configure allowed redirection URLs
3. Copy API Key and Secret to `.env`

### 3. Create Development Store
1. Create a development store in Partner dashboard
2. Install the app in the development store
3. Test the integration

## Local Development with Ngrok

### Install Ngrok
```bash
# Download from https://ngrok.com/
# Or use package manager
```

### Start Ngrok
```bash
ngrok http 3000
```

### Update Environment
```env
HOST=https://your-ngrok-url.ngrok-free.app
```

## Production Setup

See `docs/DEPLOYMENT.md` for production deployment instructions.