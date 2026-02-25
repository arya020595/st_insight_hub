# AGENTS.md — AI Agent Guide for ST Insight Hub

> **Purpose**: This file provides AI coding agents (GitHub Copilot, Cursor, Cody, etc.) with full project context to understand the architecture, codebase, conventions, and workflows at a glance.

---

## 1. Project Identity

| Field          | Value                                                        |
| -------------- | ------------------------------------------------------------ |
| **Name**       | ST Insight Hub (`BiDashboardManagementSystem`)               |
| **Type**       | Multi-tenant BI Dashboard Management System                  |
| **Framework**  | Ruby on Rails 8.1                                            |
| **Ruby**       | 3.4.7                                                        |
| **Database**   | PostgreSQL 16.1                                              |
| **Frontend**   | Hotwire (Turbo + Stimulus), Bootstrap 5.3.5, importmap-rails |
| **Auth**       | Devise (authentication) + Pundit (authorization)             |
| **Deployment** | Docker → GitHub Actions CI/CD → Production VPS               |
| **Module**     | `BiDashboardManagementSystem` (in `config/application.rb`)   |

---

## 2. What This App Does

ST Insight Hub is a **multi-tenant BI dashboard management platform** where:

1. **Superadmin** (development team) manages companies, projects, users, roles, and dashboards
2. **Companies** are client organizations, each with their own users and projects
3. **Projects** contain embedded BI **Dashboards** (iframe/embed URLs from tools like Metabase, Tableau, etc.)
4. **Client users** can only view dashboards they are explicitly assigned to
5. All actions are tracked via **Audit Logs**

### Core Business Flow

```
Company ──has_many──→ Projects ──has_many──→ Dashboards ←──HABTM──→ Users
    │                                                                  │
    └──has_many──→ Users ──belongs_to──→ Role ──has_many──→ Permissions
```

---

## 3. Architecture Overview

### 3.1 System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CLIENT BROWSER                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │
│  │  Turbo   │  │ Stimulus │  │Bootstrap │  │   Tom Select     │   │
│  │  Drive   │  │Controllers│  │  5.3.5   │  │   (multi-select) │   │
│  └────┬─────┘  └────┬─────┘  └──────────┘  └──────────────────┘   │
│       │              │                                              │
│       │   importmap-rails (ESM modules, no bundler)                │
└───────┼──────────────┼──────────────────────────────────────────────┘
        │              │
        ▼              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     RAILS 8.1 APPLICATION                           │
│                                                                     │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────────┐    │
│  │   Devise    │  │    Pundit    │  │   ApplicationController │    │
│  │   (Auth)    │  │  (Policies)  │  │   ├─ authenticate!      │    │
│  └──────┬──────┘  └──────┬───────┘  │   ├─ authorize!         │    │
│         │                │          │   └─ eager_load_perms    │    │
│         ▼                ▼          └────────────────────────────   │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │                    CONTROLLERS                              │    │
│  │  DashboardController    ProjectsController                  │    │
│  │  BiDashboardsController DashboardsController                │    │
│  │  CompaniesController    ProfilesController                  │    │
│  │  AuditLogsController    UserManagement::UsersController     │    │
│  │                         UserManagement::RolesController     │    │
│  └─────────────────────────┬──────────────────────────────────┘    │
│                             │                                       │
│  ┌──────────────────────────▼─────────────────────────────────┐    │
│  │                      MODELS                                 │    │
│  │  User ─→ Role ─→ RolesPermission ─→ Permission             │    │
│  │  Company ─→ Project ─→ Dashboard ←─→ User (HABTM)          │    │
│  │  AuditLog (polymorphic auditable)                           │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                     │
│  ┌──────────────┐  ┌───────────────┐  ┌───────────────────────┐   │
│  │  Propshaft   │  │  Active       │  │  Solid Queue/Cache/   │   │
│  │  (assets)    │  │  Storage      │  │  Cable                │   │
│  └──────────────┘  └───────────────┘  └───────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────┐
│  PostgreSQL 16.1    │
│  (Docker container) │
└─────────────────────┘
```

### 3.2 Request Lifecycle

```
Browser Request
    │
    ▼
Puma Web Server (port 3000)
    │
    ▼
Rails Router (config/routes.rb)
    │
    ▼
ApplicationController
    ├─ before_action :authenticate_user!          ← Devise
    ├─ before_action :set_current_user            ← Thread-safe current user
    ├─ before_action :eager_load_user_permissions ← Preload role→permissions (N+1 prevention)
    │
    ▼
Specific Controller Action
    ├─ authorize Record  ← Pundit policy check
    ├─ policy_scope(Record)  ← Scoped queries (multi-tenant isolation)
    ├─ Ransack search + Pagy pagination
    │
    ▼
View Rendering
    ├─ Turbo Frame (in-page updates, modals)
    ├─ Turbo Stream (flash messages, table refreshes)
    └─ Full page (standard navigation)
```

---

## 4. Directory Structure (Key Files)

```
st_insight_hub/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb      # Base: auth, permissions, audit, layout
│   │   ├── dashboard_controller.rb        # Home page (stats overview)
│   │   ├── projects_controller.rb         # CRUD projects (with Auditable concern)
│   │   ├── dashboards_controller.rb       # CRUD dashboards (nested under projects)
│   │   ├── bi_dashboards_controller.rb    # Client-facing: view embedded dashboards
│   │   ├── companies_controller.rb        # CRUD companies + assign_users
│   │   ├── audit_logs_controller.rb       # Read-only audit trail
│   │   ├── profiles_controller.rb         # User self-service profile
│   │   ├── concerns/
│   │   │   └── auditable.rb              # DSL: audit_create, audit_update, audit_delete
│   │   └── user_management/
│   │       ├── users_controller.rb        # Admin CRUD for users
│   │       └── roles_controller.rb        # Admin CRUD for roles + permissions
│   │
│   ├── models/
│   │   ├── user.rb                        # Devise + Discard + permission_codes caching
│   │   ├── role.rb                        # has_many :permissions through :roles_permissions
│   │   ├── permission.rb                  # code format: "namespace.resource.action"
│   │   ├── roles_permission.rb            # Join table with touch: true for cache invalidation
│   │   ├── company.rb                     # Discard + counter_cache (users_count, projects_count)
│   │   ├── project.rb                     # Discard + Active Storage icon_file
│   │   ├── dashboard.rb                   # Discard + HABTM users
│   │   └── audit_log.rb                   # Polymorphic auditable + JSONB data_before/after
│   │
│   ├── policies/                          # Pundit authorization
│   │   ├── application_policy.rb          # Base: auto-builds permission codes
│   │   ├── project_policy.rb             # Scope: clients see only assigned projects
│   │   ├── bi_dashboard_policy.rb        # Scope: clients see only assigned dashboards
│   │   ├── company_policy.rb             # resource: "company_management.companies"
│   │   ├── dashboard_policy.rb           # resource: "dashboard" (home page)
│   │   ├── audit_log_policy.rb           # Scope: clients see only own logs
│   │   └── user_management/
│   │       ├── role_policy.rb            # resource: "user_management.roles"
│   │       └── user_policy.rb            # resource: "user_management.users"
│   │
│   ├── services/
│   │   └── icon_file_service.rb           # Active Storage icon management
│   │
│   ├── helpers/
│   │   ├── application_helper.rb          # can_view_menu?, action_badge_class, status helpers
│   │   ├── modal_helper.rb               # modal_link_data, modal_config (Bootstrap modals)
│   │   ├── projects_helper.rb            # Project-specific view helpers
│   │   └── ransack_multi_sort_helper.rb  # Multi-column sorting support
│   │
│   ├── javascript/
│   │   ├── application.js                 # Entry: imports Turbo, Bootstrap, Stimulus controllers
│   │   └── controllers/
│   │       ├── modal_controller.js        # Bootstrap modal lifecycle + Turbo Frame integration
│   │       ├── sidebar_controller.js      # Sidebar toggle, collapse on mobile
│   │       ├── tom_select_controller.js   # Multi-select combo box (Tom Select wrapper)
│   │       ├── search_form_controller.js  # Auto-submit search with debounce
│   │       ├── multi_sort_controller.js   # Ransack multi-column sort UI
│   │       ├── icon_toggle_controller.js  # Bootstrap/custom icon switcher
│   │       └── user_form_controller.js    # Dynamic company field for user forms
│   │
│   └── views/
│       ├── layouts/
│       │   ├── dashboard/application.html.erb  # Authenticated layout (navbar+sidebar+main)
│       │   ├── application.html.erb             # Base layout (unused directly)
│       │   └── _flash.html.erb                  # Flash messages partial
│       ├── projects/                            # Index/show/new/edit + turbo_stream responses
│       ├── dashboards/                          # Form + turbo_stream (nested under projects)
│       ├── bi_dashboards/                       # Client-facing dashboard viewer (iframe embed)
│       ├── companies/                           # CRUD + assign_users + turbo_stream
│       ├── user_management/                     # Users and Roles admin
│       ├── audit_logs/                          # Index + show + modal
│       ├── profiles/                            # User profile management
│       ├── devise/                              # Auth views (login, register, password reset)
│       └── shared/                              # Reusable partials (modal, pagination, etc.)
│
├── config/
│   ├── routes.rb                          # All route definitions
│   ├── importmap.rb                       # JS module pins (Bootstrap CDN, Tom Select vendored)
│   ├── database.yml                       # PostgreSQL config (dev/test/production)
│   └── initializers/                      # Devise, Pundit, Pagy, etc.
│
├── db/
│   ├── schema.rb                          # Current database schema
│   ├── seeds.rb                           # Dev seed data (permissions, roles, companies, users, projects)
│   └── migrate/                           # Migration files
│
├── vendor/javascript/
│   └── tom-select.js                      # Vendored ESM bundle (self-contained, from esm.sh)
│
├── .github/workflows/
│   ├── ci.yml                             # CI: Brakeman, bundler-audit, importmap audit, tests
│   ├── cd-build.yml                       # Build & push Docker image to GHCR
│   └── cd-deploy.yml                      # SSH deploy to production + Slack notifications
│
├── docker-compose.yml                     # Dev: web (Rails) + db (Postgres)
├── docker-compose.production.yml          # Prod: uses GHCR image
├── Dockerfile.dev                         # Development Dockerfile
└── Dockerfile.production                  # Multi-stage production Dockerfile
```

---

## 5. Data Model & Relationships

### 5.1 Entity Relationship Diagram

```
┌─────────────┐       ┌─────────────┐       ┌──────────────────┐
│   Company    │       │    Role     │       │   Permission     │
│─────────────│       │─────────────│       │──────────────────│
│ id           │       │ id          │       │ id               │
│ name         │       │ name        │       │ code    (unique) │
│ description  │       │ description │       │ name             │
│ status       │       │ discarded_at│       │ resource         │
│ users_count  │       └──────┬──────┘       │ section          │
│ projects_count│              │              │ discarded_at     │
│ discarded_at │              │              └────────┬─────────┘
└──────┬───────┘              │                       │
       │                      │    ┌──────────────────┤
       │              ┌───────┴────┴───────┐          │
       │              │  RolesPermission   │          │
       │              │────────────────────│          │
       │              │ role_id (FK)       │──────────┘
       │              │ permission_id (FK) │
       │              │ discarded_at       │
       │              └────────────────────┘
       │
       │         ┌─────────────┐
       ├────────→│    User     │
       │         │─────────────│
       │         │ id          │
       │         │ name        │
       │         │ email       │          ┌──────────────────┐
       │         │ role_id (FK)│─────────→│      Role        │
       │         │ company_id  │          └──────────────────┘
       │         │ discarded_at│
       │         └──────┬──────┘
       │                │
       │                │ HABTM (dashboards_users)
       │                │
┌──────┴───────┐        │         ┌─────────────┐
│   Project    │        └────────→│  Dashboard   │
│──────────────│                  │─────────────│
│ id           │                  │ id           │
│ name         │                  │ name         │
│ description  │                  │ embed_url    │
│ status       │                  │ embed_type   │
│ icon         │◄─────────────────│ project_id   │
│ company_id   │  belongs_to      │ status       │
│ show_in_sidebar│                │ position     │
│ discarded_at │                  │ discarded_at │
└──────────────┘                  └──────────────┘

┌──────────────────┐
│    AuditLog      │
│──────────────────│
│ id               │
│ user_id (FK)     │
│ user_name        │
│ module_name      │
│ action           │
│ auditable_type   │  ← Polymorphic
│ auditable_id     │  ← Polymorphic
│ summary          │
│ data_before (JSONB)│
│ data_after  (JSONB)│
│ ip_address       │
│ user_agent       │
│ metadata (JSONB) │
└──────────────────┘
```

### 5.2 Key Associations

```ruby
Company  has_many :users, :projects
Project  belongs_to :company; has_many :dashboards
Dashboard belongs_to :project; has_and_belongs_to_many :users (join: dashboards_users)
User     belongs_to :role, :company; has_and_belongs_to_many :dashboards
Role     has_many :roles_permissions, :permissions (through), :users
Permission has_many :roles_permissions, :roles (through)
AuditLog belongs_to :user (optional), :auditable (polymorphic, optional)
```

### 5.3 Soft Deletes

All major models use `Discard::Model` for soft deletion:

- Records are "discarded" (set `discarded_at` timestamp) instead of destroyed
- Use `.kept` scope to filter out discarded records
- `concerns: :restorable` routes add `patch :restore` for undoing soft deletes
- Counter caches are maintained via `after_discard`/`after_undiscard` callbacks

---

## 6. Permission System

### 6.1 Permission Code Format

```
{namespace.}{resource}.{action}

Examples:
  dashboard.index                    # View home page
  projects.index                     # List projects
  projects.show                      # View project details
  user_management.users.create       # Create users
  user_management.roles.destroy      # Delete roles
  company_management.companies.update # Update companies
  bi_dashboards.show                 # View embedded dashboards
  audit_logs.index                   # View audit logs
```

### 6.2 Permission Check Flow

```
Controller action calls: authorize Record
    │
    ▼
Pundit resolves policy class (e.g., ProjectPolicy)
    │
    ▼
Policy method (e.g., index?) calls: user.has_permission?("projects.index")
    │
    ▼
User#has_permission? checks:
    ├─ return false if no role
    ├─ return true if superadmin? (bypasses ALL checks)
    └─ permission_codes.include?(code)  ← cached per-request
```

### 6.3 Policy Scoping (Multi-tenant Isolation)

```ruby
# ApplicationPolicy::Scope#resolve
if user.superadmin?
  scope.all                          # Sees everything
elsif user.has_permission?("resource.index")
  apply_role_based_scope             # Filtered by role
else
  scope.none                         # No access
end

# ProjectPolicy::Scope — clients see only assigned projects:
scope.joins(dashboards: :users).where(users: { id: user.id }).distinct

# AuditLogPolicy::Scope — clients see only own logs:
scope.where(user_id: user.id)
```

### 6.4 Default Roles (from seeds)

| Role           | Description                  | Permissions                                                                           |
| -------------- | ---------------------------- | ------------------------------------------------------------------------------------- |
| **Superadmin** | Bypasses all checks          | All (implicit)                                                                        |
| **Client**     | Read-only assigned resources | dashboard.index, projects.index/show, bi_dashboards.index/show, audit_logs.index/show |

---

## 7. Routes Map

```ruby
# Authentication
devise_for :users                    # /users/sign_in, /users/sign_out, etc.

# Root
root "dashboard#index"               # GET /
get "dashboard"                      # GET /dashboard

# User Profile
resource :profile                    # GET/PATCH /profile

# BI Dashboards (client-facing)
resources :bi_dashboards, only: [:index, :show]

# Projects + nested Dashboards
resources :projects do                # GET/POST/PATCH/DELETE /projects
  member: confirm_delete, restore
  resources :dashboards, except: [:index, :show] do
    member: confirm_delete, restore
  end
end

# Companies
resources :companies do               # GET/POST/PATCH/DELETE /companies
  member: confirm_delete, restore, assign_users, update_users, remove_user
end

# User Management (namespaced)
namespace :user_management do
  resources :users do                  # /user_management/users
    member: confirm_delete, restore
  end
  resources :roles do                  # /user_management/roles
    member: confirm_delete, restore
  end
end

# Audit Logs (read-only)
resources :audit_logs, only: [:index, :show]
```

---

## 8. Frontend Architecture

### 8.1 JavaScript Stack

```
importmap-rails (NO Node.js bundler)
    │
    ├── @hotwired/turbo-rails    ← SPA-like navigation, Turbo Frames/Streams
    ├── @hotwired/stimulus       ← Lightweight JS controllers
    ├── bootstrap (CDN ESM)      ← UI framework
    └── tom-select (vendored)    ← Multi-select combo box
```

### 8.2 Stimulus Controllers

| Controller    | File                        | Purpose                                                            |
| ------------- | --------------------------- | ------------------------------------------------------------------ |
| `modal`       | `modal_controller.js`       | Bootstrap modal lifecycle, Turbo Frame integration, dynamic sizing |
| `sidebar`     | `sidebar_controller.js`     | Sidebar toggle, mobile collapse, Turbo navigation handling         |
| `tom-select`  | `tom_select_controller.js`  | Wraps Tom Select for `<select>` elements                           |
| `search-form` | `search_form_controller.js` | Auto-submit search forms with debounce                             |
| `multi-sort`  | `multi_sort_controller.js`  | Ransack multi-column sort UI                                       |
| `icon-toggle` | `icon_toggle_controller.js` | Switch between Bootstrap icon and file upload                      |
| `user-form`   | `user_form_controller.js`   | Show/hide company field based on role selection                    |

### 8.3 Turbo Patterns Used

1. **Turbo Drive**: SPA-like full-page navigation (default)
2. **Turbo Frames**: Modal content loading via `turbo_frame_tag "modal"`
3. **Turbo Streams**: In-place updates for:
   - Flash messages (`turbo_stream.update "flash-messages"`)
   - Table row refresh (`turbo_stream.replace "table-body-id"`)
   - Modal close (injected `<script>` to dismiss Bootstrap modal)

### 8.4 CSS Architecture

```
app/assets/stylesheets/
├── application.scss       # Imports Bootstrap + page-specific styles
├── users.scss
├── roles.scss
├── audit_logs.scss
├── projects.scss
└── companies.scss

External CDN:
├── Bootstrap Icons 1.11.1
├── Flatpickr 4.6.13 (date pickers)
└── Tom Select Bootstrap 5 theme 2.4.3
```

---

## 9. Backend Patterns & Conventions

### 9.1 Controller Pattern

```ruby
class ThingsController < ApplicationController
  include Auditable  # Optional: provides audit_create, audit_update, audit_delete

  before_action :set_thing, only: %i[show edit update destroy confirm_delete]

  def index
    authorize Thing
    @q = policy_scope(Thing).kept.ransack(params[:q])
    @q.sorts = "created_at desc" if @q.sorts.empty?
    @pagy, @things = pagy(@q.result.includes(:association))
  end

  def create
    authorize Thing
    @thing = Thing.new(thing_params)
    if @thing.save
      audit_create(@thing, module_name: "things")
      reload_things_list
      respond_to do |format|
        format.html { redirect_to things_path, notice: "Thing created." }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @thing.discard                    # Soft delete
    audit_delete(@thing, module_name: "things")
    reload_things_list
    respond_to do |format|
      format.html { redirect_to things_path, notice: "Thing deleted." }
      format.turbo_stream
    end
  end

  private

  def set_thing
    @thing = Thing.kept.find(params[:id])
    authorize @thing
  end

  def reload_things_list            # For turbo_stream table refresh
    @q = policy_scope(Thing).kept.ransack(params[:q])
    @q.sorts = "created_at desc" if @q.sorts.empty?
    @pagy, @things = pagy(@q.result.includes(:association))
  end
end
```

### 9.2 Policy Pattern

```ruby
class ThingPolicy < ApplicationPolicy
  # Inherits: index?, show?, create?, update?, destroy?, confirm_delete?, restore?
  # All auto-check: user.has_permission?("things.{action}")

  private

  def permission_resource
    "things"  # Maps to permission codes like "things.index", "things.create"
  end

  class Scope < ApplicationPolicy::Scope
    private
    def permission_resource
      "things"
    end

    def apply_role_based_scope
      # Custom filtering for non-superadmin users
      scope.where(company: user.company)
    end
  end
end
```

### 9.3 Turbo Stream Response Pattern

```erb
<%# app/views/things/create.turbo_stream.erb %>
<%= turbo_stream.replace "things-table-body" do %>
  <%= render partial: "thing_row", collection: @things, as: :thing %>
<% end %>

<%= turbo_stream.update "flash-messages" do %>
  <%= render "layouts/flash" %>
<% end %>

<%= turbo_stream.append "modal" do %>
  <script>
    const modal = document.getElementById('mainModal');
    if (modal) { bootstrap.Modal.getInstance(modal)?.hide(); }
  </script>
<% end %>
```

### 9.4 Audit Logging

All CRUD operations are audited in `audit_logs` table:

- **Auditable concern** (`app/controllers/concerns/auditable.rb`): Provides `audit_create`, `audit_update`, `audit_delete`
- **Direct logging** via `log_audit` (from `ApplicationController`): For custom audit events
- Captures: `data_before` (JSONB), `data_after` (JSONB), `ip_address`, `user_agent`, `summary`

---

## 10. Development Environment

### 10.1 Docker Setup

```bash
# Start development environment
docker compose up -d

# Access Rails console
docker compose exec web rails console

# Run migrations
docker compose exec web rails db:migrate

# Seed database (blocked in production)
docker compose exec web rails db:seed

# Run tests
docker compose exec web rails test
```

### 10.2 Environment Variables (`.env`)

```
DATABASE_HOST=db
DATABASE_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=st_insight_hub_development
RAILS_ENV=development
SECRET_KEY_BASE=<generated>
```

### 10.3 Key Commands

```bash
bundle exec rubocop -a          # Lint + auto-fix (runs on pre-push hook)
bin/brakeman --no-pager         # Security scan
bin/bundler-audit               # Gem vulnerability audit
bin/importmap audit             # JS dependency audit
bin/rails db:seed               # Load dev seed data
```

---

## 11. CI/CD Pipeline

### 11.1 CI Pipeline (`ci.yml`)

```
Push/PR to main
    │
    ├─ scan_ruby: Brakeman (security) + bundler-audit (CVEs)
    ├─ scan_js: importmap audit (JS vulnerabilities)
    ├─ test: Rails unit/integration tests (PostgreSQL service)
    └─ system-test: Rails system tests (browser, PostgreSQL service)
```

### 11.2 CD Pipeline

```
Push to main (CI passes)
    │
    ▼
cd-build.yml: Build Docker image → Push to GHCR (ghcr.io)
    │
    ▼
cd-deploy.yml: SSH to production → docker compose pull → up -d → db:migrate
    │
    ├─ Slack notification: deployment started
    ├─ Health check loop (30 retries × 5s)
    └─ Slack notification: success/failure + duration
```

---

## 12. Testing

```
test/
├── controllers/        # Controller tests (request specs)
├── models/             # Model unit tests
├── integration/        # Multi-step workflow tests
├── system/             # Browser tests (Capybara)
├── helpers/            # Helper method tests
├── fixtures/           # YAML test fixtures
└── test_helper.rb      # Test configuration
```

- Framework: Minitest (Rails default)
- System tests: Capybara with Selenium
- Run: `bin/rails test` (unit/integration), `bin/rails test:system` (browser)

---

## 13. Key Gems & Their Roles

| Gem                 | Version  | Purpose                                                         |
| ------------------- | -------- | --------------------------------------------------------------- |
| `rails`             | ~> 8.1.1 | Web framework                                                   |
| `pg`                | ~> 1.1   | PostgreSQL adapter                                              |
| `devise`            | latest   | Authentication (login, register, password reset)                |
| `pundit`            | latest   | Authorization (policy-based access control)                     |
| `pagy`              | latest   | Fast pagination                                                 |
| `ransack`           | latest   | Search & filtering with sort                                    |
| `discard`           | ~> 1.3   | Soft deletes (`discarded_at` timestamp)                         |
| `importmap-rails`   | latest   | ESM JavaScript without bundler                                  |
| `turbo-rails`       | latest   | Hotwire Turbo (Drive, Frames, Streams)                          |
| `stimulus-rails`    | latest   | Hotwire Stimulus (JS controllers)                               |
| `bootstrap`         | ~> 5.3   | CSS framework (via sassc-rails)                                 |
| `propshaft`         | latest   | Asset pipeline (replaces Sprockets in Rails 8)                  |
| `image_processing`  | ~> 1.2   | Active Storage image variants                                   |
| `solid_cache`       | latest   | Database-backed Rails.cache                                     |
| `solid_queue`       | latest   | Database-backed Active Job                                      |
| `solid_cable`       | latest   | Database-backed Action Cable                                    |
| `strong_migrations` | latest   | Safe migration checker                                          |
| `audited`           | ~> 5.8   | Model-level audit trail (gem, supplementary to custom AuditLog) |
| `dry-monads`        | ~> 1.9   | Functional result types                                         |
| `aasm`              | ~> 5.5   | State machine library                                           |
| `sidekiq`           | ~> 8.1   | Background job processing                                       |

---

## 14. Common Modification Scenarios

### Adding a New Permission-Protected Resource

1. Create migration for the new table
2. Create model with `include Discard::Model`
3. Add permission seeds in `db/seeds.rb`
4. Create policy inheriting `ApplicationPolicy`, implement `permission_resource`
5. Create controller following the pattern in Section 9.1
6. Add routes in `config/routes.rb`
7. Add sidebar link in `app/views/layouts/dashboard/_sidebar.html.erb` with `can_view_menu?` guard
8. Create views with Turbo Frame/Stream support

### Adding a New Stimulus Controller

1. Create `app/javascript/controllers/{name}_controller.js`
2. It auto-registers via `eagerLoadControllersFrom("controllers", application)`
3. Use in views: `data-controller="{name}"`

### Adding a New JS Library

1. Download ESM bundle: `curl -o vendor/javascript/lib.js "https://esm.sh/lib@version?bundle-deps"`
2. Pin in `config/importmap.rb`: `pin "lib", to: "lib.js"`
3. Import in Stimulus controller: `import Lib from "lib"`

---

## 15. Gotchas & Known Patterns

1. **Turbo Frame + Flash Messages**: Forms inside `turbo_frame_tag "modal"` need `format.turbo_stream` responses to update flash messages (they're outside the frame).

2. **Permission Cache**: `User#permission_codes` is memoized with a composite key (`user_id + role_id + role.updated_at`). `RolesPermission` touches its `Role` on save to invalidate.

3. **`first_accessible_path`**: When a user has limited permissions, `User#first_accessible_path` determines where to redirect after login. Falls back to `:profile_path` to avoid infinite loops.

4. **Soft Delete + Counter Cache**: `after_discard`/`after_undiscard` callbacks manually adjust counter caches since Rails counter_cache doesn't account for soft deletes.

5. **importmap + ESM only**: No Node.js, no webpack, no esbuild. All JS must be ESM. UMD/CJS bundles won't work with importmap.

6. **`database.yml` ERB**: All sections (including `production:`) are parsed by ERB even in development. Use `ENV["KEY"]` (returns nil) not `ENV.fetch("KEY")` (raises KeyError) for production-only env vars.

7. **Propshaft vs Sprockets**: This app uses **both** — `propshaft` as the primary asset pipeline (gem in Gemfile) and `sassc-rails` for Bootstrap SCSS compilation. The `manifest.js` uses Sprockets-style directives for vendor JS.

8. **Multi-tenant through dashboard assignment**: Client users don't see all dashboards in their company's projects — they only see dashboards they're explicitly assigned to via `dashboards_users` join table.

---

## 16. Documentation Index

| Document               | Path                                        | Content                                                     |
| ---------------------- | ------------------------------------------- | ----------------------------------------------------------- |
| Quick Start            | `docs/QUICK_START.md`                       | Setup and first run                                         |
| Architecture Blueprint | `docs/ARCHITECTURE_BLUEPRINT.md`            | Detailed system design                                      |
| Devise Guide           | `docs/DEVISE_GUIDE.md`                      | Authentication setup                                        |
| Ransack Guide          | `docs/ransack/RANSACK_GUIDE.md`             | Search & filtering                                          |
| Multi-Sort             | `docs/ransack/MULTI_SORT_IMPLEMENTATION.md` | Multi-column sort                                           |
| Tom Select Guide       | `docs/TOM_SELECT_GUIDE.md`                  | Multi-select combo box                                      |
| Project Icon Upload    | `docs/PROJECT_ICON_UPLOAD.md`               | Active Storage icons (SVG, PNG, JPEG, WEBP, GIF; max 500KB) |
| Dashboard Embed Guide  | `docs/DASHBOARD_EMBED_GUIDE.md`             | iframe vs embed_url — when to use each                      |
| Production Deployment  | `docs/PRODUCTION_DEPLOYMENT_GUIDE.md`       | Deployment guide                                            |
