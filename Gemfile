source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.1"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.21"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# Authentication
gem "devise"

# Pagination
gem "pagy"

# Authorization (Pundit policies)
gem "pundit"

# Search and filtering
gem "ransack"

# Background jobs (Sidekiq 8.x)
gem "sidekiq", "~> 8.1"

# dry-rb: functional programming helpers
gem "dry-monads", "~> 1.9"

# State machine library for Ruby objects (AASM) — used to model object states and transitions
gem "aasm", "~> 5.5", ">= 5.5.2"

# Audit trail for models - tracks who created/updated records and what changed
gem "audited", "~> 5.8"

# Strong Migrations to help write safe database migrations
gem "strong_migrations"

# Soft delete for models
gem "discard", "~> 1.3"

# Bootstrap 5 framework integration
gem "bootstrap", "~> 5.3", ">= 5.3.5"

# Sass compiler for CSS preprocessing (required for Bootstrap SCSS)
gem "sassc-rails"

# Font Awesome
gem "font-awesome-rails"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # Annotate models with schema information
  gem "annotate", require: false

  # Faker for generating fake data
  gem "faker"

  # Bullet gem to help detect N+1 queries and unused eager loading
  gem "bullet", "~> 8.1"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"

  # Code completion and inline documentation for Ruby/Rails [https://solargraph.org]
  gem "solargraph", "~> 0.58.1", require: false

  # HTML formatter for Ruby/Rails code [https://github.com/threedaymonk/htmlbeautifier]
  gem "htmlbeautifier", require: false
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end
