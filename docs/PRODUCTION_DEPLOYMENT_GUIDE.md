# 🚀 Production Deployment Guide (GHCR)

Complete step-by-step guide to deploy Rails application to production server using GitHub Container Registry (GHCR) and automated CI/CD.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Server Setup](#server-setup)
- [GitHub Setup](#github-setup)
- [Initial Deployment](#initial-deployment)
- [CI/CD Workflows](#cicd-workflows)
- [Running the Application](#running-the-application)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Prerequisites

### Local Machine:

- Git installed
- SSH client
- Text editor

### Production Server:

- Ubuntu/Debian Linux
- Minimum 2GB RAM, 20GB disk
- Public IP address (example: `46.202.163.155`)
- User with sudo access (example: `stadmin`)

---

## 🖥️ Server Setup

### 1. Connect to Server

```bash
ssh your-username@your-server-ip
# Example: ssh stadmin@46.202.163.155
```

### 2. Install Docker & Docker Compose

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group (replace 'stadmin' with your username)
sudo usermod -aG docker stadmin

# Logout and login again for group changes to take effect
exit
```

**Re-login to server:**

```bash
ssh stadmin@46.202.163.155
```

**Verify Docker installation:**

```bash
docker --version
docker compose version
```

### 3. Create Project Directory

```bash
# Create directory for the application
mkdir -p /home/stadmin/st_intent_harvest
cd /home/stadmin/st_intent_harvest
```

### 4. Upload `docker-compose.yml`

Create `docker-compose.yml` on the server:

```bash
nano docker-compose.yml
```

Paste this content:

```yaml
services:
  db:
    image: postgres:16.1-alpine
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-postgres}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB:-st_intent_harvest_production}
      POSTGRES_INITDB_ARGS: "--encoding=UTF8 --locale=C"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-postgres}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - app_network
    restart: unless-stopped

  web:
    image: ${DOCKER_IMAGE:-ghcr.io/arya020595/st_intent_harvest:latest}
    environment:
      # Database connection
      DATABASE_URL: postgresql://${POSTGRES_USER:-postgres}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB:-st_intent_harvest_production}

      # Rails configuration
      SECRET_KEY_BASE: ${SECRET_KEY_BASE}
      RAILS_ENV: production
      RAILS_LOG_TO_STDOUT: "true"
      RAILS_SERVE_STATIC_FILES: "true"
      RAILS_MAX_THREADS: ${RAILS_MAX_THREADS:-5}
      WEB_CONCURRENCY: ${WEB_CONCURRENCY:-2}

      # SSL Configuration (set to 'true' if using HTTPS)
      RAILS_FORCE_SSL: ${RAILS_FORCE_SSL:-false}
      RAILS_ASSUME_SSL: ${RAILS_ASSUME_SSL:-false}

      # Timezone
      TZ: Asia/Jakarta
    ports:
      - "${PORT:-3005}:3000"
    volumes:
      - storage_data:/rails/storage
      - log_data:/rails/log
    depends_on:
      db:
        condition: service_healthy
    networks:
      - app_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/up"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  postgres_data:
  storage_data:
  log_data:

networks:
  app_network:
    driver: bridge
```

Save: `Ctrl+O`, `Enter`, `Ctrl+X`

### 5. Upload `.env` File

Create `.env` file with your production credentials:

```bash
nano .env
```

Paste this content (replace with your actual values):

```env
# Server Configuration
PORT=3005

# Database Configuration
POSTGRES_USER=postgres
POSTGRES_PASSWORD=YourSecurePassword123!
POSTGRES_DB=st_intent_harvest_production

# Rails Configuration
SECRET_KEY_BASE=your_128_character_secret_key_here_generate_with_rails_secret

# SSL Configuration (set to 'true' when using HTTPS with Nginx)
RAILS_FORCE_SSL=false
RAILS_ASSUME_SSL=false

# Performance Tuning
RAILS_MAX_THREADS=5
WEB_CONCURRENCY=2
```

Save: `Ctrl+O`, `Enter`, `Ctrl+X`

**🔐 Generate SECRET_KEY_BASE:**

```bash
# On your local machine with Ruby/Rails installed:
rails secret

# Or use this online (not recommended for production):
openssl rand -hex 64
```

**⚠️ Important:** Keep `.env` file secure! Never commit to Git.

### 6. Upload Nginx Configuration (Optional - for HTTPS)

If you want to use a domain with HTTPS:

```bash
nano nginx.conf
```

Paste this content:

```nginx
upstream rails_app {
    server localhost:3005;
}

server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com www.your-domain.com;

    # SSL certificates (will be added by Certbot)
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Proxy settings
    location / {
        proxy_pass http://rails_app;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Static files
    location ~* ^/assets/ {
        proxy_pass http://rails_app;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

Save: `Ctrl+O`, `Enter`, `Ctrl+X`

**Note:** Nginx setup is optional. For quick deployment, skip this and use HTTP with IP:PORT.

---

## 🔧 GitHub Setup

### 1. Setup SSH Key for GitHub Actions

On your **local machine**:

```bash
# Generate SSH key pair
ssh-keygen -t ed25519 -f ~/.ssh/github_actions_deploy -C "github-actions-deploy"

# Display public key
cat ~/.ssh/github_actions_deploy.pub
```

**Copy the public key output.**

On your **production server**:

```bash
# Add public key to authorized_keys
nano ~/.ssh/authorized_keys

# Paste the public key at the end of the file
# Save: Ctrl+O, Enter, Ctrl+X

# Set correct permissions
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

**Test SSH connection from local machine:**

```bash
ssh -i ~/.ssh/github_actions_deploy stadmin@46.202.163.155
```

If successful, you should connect without password!

### 2. Create GitHub Secrets

Go to your GitHub repository:

```
https://github.com/YOUR_USERNAME/st_intent_harvest/settings/secrets/actions
```

Click **"New repository secret"** and create these 4 secrets:

| Secret Name          | Value               | Example                                                            |
| -------------------- | ------------------- | ------------------------------------------------------------------ |
| `PRODUCTION_HOST`    | Your server IP      | `46.202.163.155`                                                   |
| `PRODUCTION_USER`    | SSH username        | `stadmin`                                                          |
| `PRODUCTION_SSH_KEY` | Private key content | `cat ~/.ssh/github_actions_deploy`                                 |
| `SLACK_WEBHOOK_URL`  | Slack webhook URL   | `https://hooks.slack.com/services/TT0F5RLA1/B0A0GUJFR46/zlkkte...` |

**For PRODUCTION_SSH_KEY:**

```bash
# On local machine, display private key:
cat ~/.ssh/github_actions_deploy

# Copy ENTIRE output including:
# -----BEGIN OPENSSH PRIVATE KEY-----
# ... content ...
# -----END OPENSSH PRIVATE KEY-----

# Paste into GitHub Secret
```

**For SLACK_WEBHOOK_URL:**

**Option 1: Create new Slack Webhook**

1. Open your Slack Workspace
2. Click workspace name → **Settings & administration** → **Manage apps**
3. Search for "**Incoming WebHooks**" and click on it
4. Click "**Add to Slack**" or "**Add Configuration**"
5. Select the **channel** where you want to receive deployment notifications (e.g., `#deployments`, `#production-alerts`)
6. Click "**Add Incoming WebHooks integration**"
7. **Copy the Webhook URL** (format: `https://hooks.slack.com/services/T.../B.../xxx`)
8. Paste into GitHub Secret

**Option 2: Get existing Webhook URL**

1. Go to **https://api.slack.com/apps**
2. Select your workspace
3. Find the app "Incoming WebHooks"
4. Click **Incoming Webhooks** → View **Webhook URLs**
5. Copy the URL for your desired channel

**Option 3: Use Organization Webhook**

If your team already has a webhook, ask your DevOps/Admin for the `SLACK_WEBHOOK_URL`.

### 3. Verify Workflow Files

Ensure you have these 3 workflow files in your repository:

**`.github/workflows/ci.yml`** - Run tests on Pull Requests
**`.github/workflows/cd-build.yml`** - Build Docker image on push to main
**`.github/workflows/cd-deploy.yml`** - Deploy to server after build success

These files are already in your repository.

---

## 🚢 Initial Deployment

### Option A: Manual First Deployment

On your **production server**:

```bash
cd /home/stadmin/st_intent_harvest

# Pull the latest image from GHCR
docker compose pull

# Start services
docker compose up -d

# Wait for services to be ready (30 seconds)
sleep 30

# Check status
docker compose ps

# Create database
docker compose exec web rails db:create

# Run migrations
docker compose exec web rails db:migrate

# Seed database (creates admin user)
docker compose exec web rails db:seed

# View logs
docker compose logs -f web
```

**🎉 Your app is now running at:** `http://YOUR_SERVER_IP:3005`

**Default admin credentials:**

- Email: `admin@example.com`
- Password: `ChangeMe123!`

**⚠️ IMPORTANT:** Change the admin password immediately after first login!

### Option B: Automated Deployment via GitHub Actions

1. **Commit and push your code to `develop` branch**

```bash
git add .
git commit -m "Setup production deployment"
git push origin develop
```

2. **Create Pull Request: `develop` → `main`**

Go to GitHub:

```
https://github.com/YOUR_USERNAME/st_intent_harvest/pulls
```

- Click "New Pull Request"
- Base: `main`, Compare: `develop`
- Create Pull Request
- Wait for CI to pass ✅

3. **Merge to `main`**

- Click "Merge pull request"
- Confirm merge

4. **Monitor GitHub Actions**

Go to Actions tab:

```
https://github.com/YOUR_USERNAME/st_intent_harvest/actions
```

You'll see 2 workflows running:

1. ✅ **Build & Push Docker Image** (3-5 minutes)
2. ✅ **Deploy to Production** (auto-triggers after build success)

3. **Verify Deployment**

Check deployment logs in GitHub Actions. You should see:

```
📦 Pulling latest Docker image...
🔄 Restarting services...
⏳ Waiting for services to be ready...
🗄️  Running database migrations...
🏥 Health check...
✅ App is healthy!
📊 Container status:
✅ Deployment completed successfully!
🌐 App: http://46.202.163.155:3005
```

6. **Setup Database (First Time Only)**

SSH to server and run:

```bash
cd /home/stadmin/st_intent_harvest
docker compose exec web rails db:create
docker compose exec web rails db:seed
```

---

## 🔄 CI/CD Workflows

### Workflow Overview

```
┌─────────────────────────────────────────────────────────────┐
│  1️⃣  Developer creates feature branch                      │
│     git checkout -b feature/new-feature                     │
│     ... work on code ...                                    │
│     git push origin feature/new-feature                     │
│                                                             │
│     ❌ No CI runs (save resources)                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  2️⃣  Create Pull Request: feature/* → develop              │
│                                                             │
│     ✅ CI Workflow runs (ci.yml)                           │
│        - Run Rubocop                                        │
│        - Run Brakeman                                       │
│        - Precompile assets                                  │
│        - Run tests                                          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  3️⃣  Merge to develop → Test locally                       │
│                                                             │
│     ❌ No build/deploy (develop is for testing)            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  4️⃣  Create Pull Request: develop → main                   │
│                                                             │
│     ✅ CI Workflow runs again (final validation)           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  5️⃣  Merge to main                                         │
│                                                             │
│     ✅ Build Workflow runs (cd-build.yml)                  │
│        - Build Docker image                                 │
│        - Push to ghcr.io/arya020595/st_intent_harvest       │
│        - Tag as 'latest' and 'main-{sha}'                   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  6️⃣  Auto-Deploy (cd-deploy.yml)                           │
│                                                             │
│     ✅ Deploy Workflow triggers automatically              │
│        - SSH to production server                           │
│        - Pull latest image                                  │
│        - Restart containers                                 │
│        - Run migrations                                     │
│        - Health check                                       │
│        - Show logs and status                               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  🎉 DEPLOYED!                                              │
│     http://46.202.163.155:3005                             │
└─────────────────────────────────────────────────────────────┘
```

### Workflow Files Explained

#### 1. CI Workflow (`ci.yml`)

**Trigger:** Pull Request to `develop` or `main`

**Purpose:** Run code quality checks and tests

**Steps:**

- Setup PostgreSQL test database
- Install Ruby and gems
- Run Rubocop (linter)
- Run Brakeman (security scanner)
- Precompile assets
- Run tests (when enabled)

**When it runs:**

- Creating PR from feature branch → develop
- Creating PR from develop → main
- Updating PR with new commits

#### 2. Build Workflow (`cd-build.yml`)

**Trigger:** Push to `main` branch

**Purpose:** Build Docker image and push to GHCR

**Steps:**

- Checkout code
- Setup Docker Buildx
- Login to GitHub Container Registry
- Extract metadata (tags, labels)
- Build Docker image from `Dockerfile.production`
- Push image with tags:
  - `ghcr.io/arya020595/st_intent_harvest:latest`
  - `ghcr.io/arya020595/st_intent_harvest:main-{commit-sha}`
- Cache layers for faster builds

**Artifacts:**

- Docker image in GHCR (public/private based on repo settings)

#### 3. Deploy Workflow (`cd-deploy.yml`)

**Trigger:** After successful build on `main` branch

**Purpose:** Automatically deploy to production server

**Steps:**

1. SSH to production server
2. Pull latest Docker image from GHCR
3. Restart containers with `docker compose up -d`
4. Wait 15 seconds for services to start
5. Run database migrations
6. Health check with 5 retries
7. Display container status
8. Show recent logs (20 lines)
9. Print success message with app URL

**Manual Trigger:** Can also be triggered manually via GitHub Actions UI

---

## 🚀 Running the Application

### Method 1: Automated Deployment (Recommended)

**When to use:** Regular deployments after development

**Steps:**

1. **Merge to main branch** (via Pull Request)
2. **Wait for GitHub Actions** to complete
3. **Done!** App automatically deployed

**Monitoring:**

- Go to: `https://github.com/YOUR_USERNAME/st_intent_harvest/actions`
- Watch "Build & Push Docker Image" workflow
- Watch "Deploy to Production" workflow
- Check deployment logs for any errors

### Method 2: Manual Deployment

**When to use:** First deployment, testing, or troubleshooting

**On production server:**

```bash
# Navigate to project directory
cd /home/stadmin/st_intent_harvest

# Pull latest image
docker compose pull

# Start/restart services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f web
```

### Common Commands

#### View Application Logs

```bash
# Follow logs (real-time)
docker compose logs -f web

# Last 100 lines
docker compose logs --tail=100 web

# All services
docker compose logs -f
```

#### Check Container Status

```bash
# List running containers
docker compose ps

# Detailed status
docker compose ps -a

# Health check status
docker inspect st_intent_harvest-web-1 | grep -A 10 Health
```

#### Restart Services

```bash
# Restart web service only
docker compose restart web

# Restart all services
docker compose restart

# Stop and start (fresh start)
docker compose down
docker compose up -d
```

#### Database Operations

```bash
# Run migrations
docker compose exec web rails db:migrate

# Seed database
docker compose exec web rails db:seed

# Rails console
docker compose exec web rails console

# Database console
docker compose exec web rails dbconsole

# Database backup
docker compose exec db pg_dump -U postgres st_intent_harvest_production > backup.sql

# Restore database
cat backup.sql | docker compose exec -T db psql -U postgres st_intent_harvest_production
```

#### Update Application

```bash
# Pull latest code (manual method)
docker compose pull
docker compose up -d
docker compose exec web rails db:migrate

# Via GitHub Actions (automated method)
# Just merge to main branch!
```

### Performance Monitoring

```bash
# Container resource usage
docker stats

# Disk usage
docker system df

# Logs size
du -sh log/

# Database size
docker compose exec db psql -U postgres -d st_intent_harvest_production -c "SELECT pg_size_pretty(pg_database_size('st_intent_harvest_production'));"
```

---

## 🔒 Security Checklist

- [ ] Change default admin password immediately
- [ ] Set strong `POSTGRES_PASSWORD` in `.env`
- [ ] Use 128+ character `SECRET_KEY_BASE`
- [ ] Keep `.env` file secure (never commit to Git)
- [ ] Setup firewall (ufw/iptables)
- [ ] Enable HTTPS with SSL certificate (if using domain)
- [ ] Regular backups of database
- [ ] Keep Docker and system updated
- [ ] Monitor logs for suspicious activity
- [ ] Use strong SSH key authentication
- [ ] Disable password-based SSH login

---

## 🐛 Troubleshooting

### Container Won't Start

```bash
# Check logs
docker compose logs web

# Check environment variables
docker compose config

# Restart from scratch
docker compose down
docker compose up -d
```

### Database Connection Error

```bash
# Check database status
docker compose ps db

# Check database logs
docker compose logs db

# Restart database
docker compose restart db

# Verify DATABASE_URL
docker compose exec web env | grep DATABASE_URL
```

### Migration Fails

```bash
# Check if database exists
docker compose exec web rails db:migrate:status

# Rollback last migration
docker compose exec web rails db:rollback

# Drop and recreate (⚠️ destroys data!)
docker compose exec web rails db:drop db:create db:migrate db:seed
```

### Image Pull Fails

```bash
# Check if image exists
docker pull ghcr.io/arya020595/st_intent_harvest:latest

# Login to GHCR (if private repo)
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Check GitHub Actions build logs
# https://github.com/YOUR_USERNAME/st_intent_harvest/actions
```

### GitHub Actions Deploy Fails

**Check SSH connection:**

```bash
# From local machine
ssh -i ~/.ssh/github_actions_deploy stadmin@46.202.163.155
```

**Check GitHub Secrets:**

- Go to: Settings → Secrets and variables → Actions
- Verify all 3 secrets exist:
  - PRODUCTION_HOST
  - PRODUCTION_USER
  - PRODUCTION_SSH_KEY

**Check deployment logs:**

- Go to: Actions → Deploy to Production → Latest run
- Read error messages

### Health Check Fails

```bash
# Manual health check
curl http://localhost:3005/up

# Check if port is listening
netstat -tlnp | grep 3005

# Check firewall
sudo ufw status

# Allow port (if blocked)
sudo ufw allow 3005/tcp
```

### Out of Disk Space

```bash
# Check disk usage
df -h

# Clean up Docker
docker system prune -a --volumes

# Clean up old logs
docker compose exec web rails log:clear
```

---

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Rails Deployment Guide](https://guides.rubyonrails.org/deploying.html)
- [Nginx SSL Setup Guide](./NGINX_SSL_SETUP.md)

---

## 🎉 Success!

Your application should now be running at:

**HTTP:** `http://YOUR_SERVER_IP:3005`

**Example:** `http://46.202.163.155:3005`

**Default Login:**

- Email: `admin@example.com`
- Password: `ChangeMe123!`

**⚠️ Remember to:**

1. Change admin password
2. Setup regular database backups
3. Monitor logs regularly
4. Keep system updated

---

**Need help?** Check the [Troubleshooting](#troubleshooting) section or create an issue on GitHub.

**Happy Deploying! 🚀**
