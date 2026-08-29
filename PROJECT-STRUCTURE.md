# Project Structure Documentation

## Final Organized Structure

```
Vehicle Selector Pro/
├── app/                              # Main Rails application
│   ├── controllers/                   # Application controllers
│   │   ├── admin/                    # Admin dashboard controllers
│   │   ├── app_proxy/                # Shopify App Proxy controllers
│   │   └── webhooks/                 # Webhook handlers
│   ├── jobs/                         # Background jobs
│   │   ├── metafields/               # Metafield sync jobs
│   │   ├── vehicles/                 # Vehicle management jobs
│   │   └── webhooks/                 # Webhook processing jobs
│   ├── models/                       # ActiveRecord models
│   │   ├── shop.rb                    # Shopify shop model
│   │   ├── vehicle.rb                 # Vehicle model
│   │   ├── vehicle_product_fitment.rb # Fitment mapping
│   │   ├── metafield_sync_log.rb      # Sync tracking
│   │   └── app_setting.rb             # App configuration
│   ├── services/                     # Business logic services
│   │   ├── shopify/                   # Shopify API services
│   │   ├── app_proxy_signature_verifier.rb
│   │   ├── bulk_fitment_importer.rb
│   │   ├── fitment_search_service.rb
│   │   └── vehicle_hierarchy_service.rb
│   └── views/                        # View templates
│       ├── admin/                    # Admin dashboard views
│       ├── layouts/                  # Layout templates
│       └── home/                     # Home page views
├── config/                           # Rails configuration
│   ├── environments/                 # Environment-specific configs
│   ├── initializers/                 # Initialization scripts
│   ├── application.rb                # Rails application config
│   ├── database.yml                   # Database configuration
│   ├── routes.rb                      # Application routes
│   ├── puma.rb                        # Puma server config
│   ├── shopify_app.rb                 # Shopify app integration
│   └── sidekiq.rb                     # Sidekiq configuration
├── db/                               # Database files
│   ├── migrate/                       # Database migrations
│   ├── schema.rb                      # Database schema
│   └── seeds.rb                       # Seed data
├── extensions/                       # Shopify Theme Extensions
│   ├── theme-app-extension/          # Basic theme extension
│   │   ├── blocks/                    # Theme blocks
│   │   └── shopify.app.toml          # Extension config
│   └── vehicle-selector-pro-extension/ # Enhanced extension
│       ├── assets/                    # JavaScript & CSS
│       │   ├── vehicle-selector.js
│       │   └── vehicle-selector.css
│       ├── blocks/                    # Theme blocks
│       │   ├── vehicle_selector_filter.liquid
│       │   └── product_fitment_badge.liquid
│       ├── locales/                    # Localization files
│       ├── snippets/                   # Reusable snippets
│       └── shopify.extension.toml      # Extension config
├── spec/                             # Test suite
│   ├── services/                      # Service tests
│   ├── spec_helper.rb                 # Test configuration
│   └── test_runner.rb                 # Test runner
├── public/                           # Public assets
│   └── command-center.css            # Demo styling
├── docs/                             # Documentation
│   ├── ARCHITECTURE.md               # System architecture
│   ├── API.md                        # API documentation
│   ├── DEPLOYMENT.md                 # Deployment guide
│   ├── SETUP.md                      # Setup instructions
│   └── DEMO_SCRIPT.md                # Demo script
├── demo/                             # Demo materials
│   ├── index.html                    # Enhanced demo interface
│   ├── demo-alternative.html          # Alternative demo
│   ├── command-center.css            # Demo styling
│   └── video/                        # Demo video files
│       ├── Vehicle_Selector_Pro_2.5min_Demo.webm
│       └── frame-*.png                # Video frames
├── assets/                           # Additional assets
│   └── tts/                          # Text-to-speech assets
├── Gemfile                           # Ruby dependencies
├── Dockerfile                        # Container configuration
├── fly.toml                          # Fly.io deployment config
├── Rakefile                          # Rails tasks
├── config.ru                         # Rack configuration
├── .env.example                      # Environment template
├── .gitignore                        # Git ignore rules
├── README.md                         # Main documentation
├── CLIENT_DELIVERY.md                # Client delivery information
├── shopify.app.toml                  # Shopify app configuration
├── Vehicle Selector Pro (Ruby on Rails).pdf  # Original requirements
└── Vehicle Selector Pro (Ruby on Rails).docx  # Original requirements
```

## File Purposes

### Core Application Files
- **app/** - Main Rails application code
- **config/** - Application configuration
- **db/** - Database schema and migrations
- **Gemfile** - Ruby dependencies
- **Rakefile** - Rails task definitions

### Shopify Integration
- **extensions/** - Shopify Theme App Extensions
- **shopify.app.toml** - Shopify app configuration
- **app/services/shopify/** - Shopify API integration

### Demo & Presentation
- **demo/** - Interactive demo interfaces
- **demo/video/** - Pre-recorded demo video
- **public/command-center.css** - Demo styling

### Documentation
- **README.md** - Main project documentation
- **docs/** - Detailed technical documentation
- **CLIENT_DELIVERY.md** - Client-focused delivery info

### Configuration Files
- **.env.example** - Environment variable template
- **fly.toml** - Fly.io deployment configuration
- **Dockerfile** - Container configuration
- **.gitignore** - Git ignore patterns

## Development Workflow

### Local Development
1. Set up environment variables from `.env.example`
2. Run `bundle install` for dependencies
3. Run `rails db:migrate` for database setup
4. Run `rails server` to start application
5. Run `sidekiq` for background jobs

### Testing
- Run `ruby spec/test_runner.rb` for test suite
- Test coverage for models, services, and controllers

### Deployment
- Follow `docs/DEPLOYMENT.md` for Fly.io deployment
- Configure environment variables via Fly.io secrets
- Deploy with `fly deploy` command

## Important Notes

### Security Files (Never Commit)
- `.env` - Contains actual API keys and secrets
- Any files with real credentials

### Git Tracking
- Source code is tracked in Git
- Documentation is tracked in Git
- Configuration templates are tracked in Git
- Sensitive files are excluded via `.gitignore`

### Dependencies
- Ruby 3.2+ required
- Rails 7.1+ required
- PostgreSQL or SQLite for database
- Redis for background jobs

## GitHub Repository Structure

When pushed to GitHub, the repository will contain:
- Complete source code
- Documentation
- Configuration templates
- Demo materials
- No sensitive credentials

This structure provides a clean, professional organization suitable for client delivery and future development.