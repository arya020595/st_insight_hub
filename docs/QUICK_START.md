# 🚀 Quick Start Guide

## First Time Setup (5 minutes)

```bash
# 1. Copy environment file
cp .env.example .env

# 2. Build Docker images (takes 5-10 minutes first time)
docker compose build

# 3. Start all services
docker compose up -d

# 4. Setup database
docker compose exec web rails db:create
docker compose exec web rails db:migrate
docker compose exec web rails db:seed

# 5. Open your browser
# Visit: http://localhost:3000
# Login: superadmin@example.com / password123
```

## Daily Workflow

```bash
# Start work
docker compose up -d

# Stop work
docker compose down

# View logs
docker compose logs -f web
```

## Common Commands

### No `bundle exec` needed! 🎉

```bash
# Run migrations
docker compose exec web rails db:migrate

# Open Rails console
docker compose exec web rails console

# Run tests
docker compose exec web rails test

# Generate migration
docker compose exec web rails generate migration AddColumnToUsers

# View routes
docker compose exec web rails routes

# Install new gems (after updating Gemfile)
# Just restart - gems install automatically!
docker compose restart web

# Open bash terminal
docker compose exec web bash
```

### Interactive Debugging

When you need to debug with `binding.pry` or `byebug`:

```bash
# Stop the background web service
docker compose stop web

# Run interactively with ports exposed
docker compose run --service-ports web

# Now you can interact with debugger in terminal!
# Press Ctrl+C when done

# Restart background service
docker compose up -d web
```

**What `docker compose run --service-ports web` does:**

- Runs Rails server in **interactive mode** (you can see output and type input)
- Exposes ports (so `http://localhost:3000` still works)
- Allows you to interact with debuggers like `binding.pry` or `byebug`
- Perfect for debugging, running console, or any interactive task

**Use cases:**

- Debugging with `binding.pry` in controllers/models
- Running interactive Rails console
- Running generators that need input
- Any task that needs to see real-time output

## Troubleshooting

### Port already in use?

```bash
# PostgreSQL (5432)
sudo systemctl stop postgresql

# Or change ports in docker-compose.yml to 5433:5432
```

### Database connection error?

```bash
# Restart services
docker compose restart web

# Check database is running
docker compose exec db psql -U postgres -c "SELECT version();"
```

### Code changes not reflecting?

- No restart needed! Volume mounts sync code in real-time.
- For gem changes: Just restart the container `docker compose restart web`

### New gem added - "Run `bundle install` to install missing gems"?

This happens when someone added a new gem and you pulled their changes.

**Solution: Just run `docker compose up -d`** 🎉

```bash
# Gems install automatically on container startup!
docker compose up -d

# Watch the installation progress (optional)
docker compose logs -f web
```

**How this works:**

- The Docker entrypoint automatically runs `bundle check || bundle install` on every startup
- Your `docker-compose.yml` uses a persistent `bundle_cache` volume to store gems
- New gems are installed automatically without rebuilding!
- The server starts automatically after gem installation completes

**If you see gems being installed:**

- This is normal! Just wait ~1-2 minutes for installation to complete
- The Rails server will start automatically when done
- You can watch progress with `docker compose logs -f web`

### Reset everything?

```bash
docker compose down -v  # Remove containers and volumes
docker compose build    # Rebuild images
docker compose up -d    # Start fresh
```

## 🆘 Need Help?

Having issues? Check the logs first:

```bash
# View all logs
docker compose logs

# Follow web logs
docker compose logs -f web

# View database logs
docker compose logs db
```

Common issues:

- **Port conflicts**: Stop local PostgreSQL service
- **Database errors**: Run `docker compose restart web`
- **Code not updating**: Check volume mounts in docker-compose.yml
- **Permission errors**: Run `docker compose down && docker compose up -d`
