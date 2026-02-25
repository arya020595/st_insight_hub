# CLAUDE.md — Claude Code / Claude Agent Context for ST Insight Hub

> **For Claude (Anthropic)**: This file contains structured context to help you understand, navigate, and modify the ST Insight Hub codebase efficiently. Read this file first before making any changes.

---

## Identity

- **Project**: ST Insight Hub — A multi-tenant BI Dashboard Management System
- **Rails Module**: `BiDashboardManagementSystem`
- **Stack**: Rails 8.1, Ruby 3.4.7, PostgreSQL 16.1, Hotwire (Turbo + Stimulus), Bootstrap 5.3.5, importmap-rails
- **Auth**: Devise (authentication) + Pundit (authorization with permission codes)
- **Container**: Docker Compose (dev: `web` + `db` services)

---

## Quick Reference — File Locations

### When modifying...

| Task                             | Files to touch                                                                                   |
| -------------------------------- | ------------------------------------------------------------------------------------------------ |
| Add a new page/feature           | `config/routes.rb`, new controller, new policy, new views, sidebar partial                       |
| Change permissions               | `db/seeds.rb` (permission definitions), run `rails db:seed`                                      |
| Add a model                      | `db/migrate/`, `app/models/`, include `Discard::Model` if soft-deletable                         |
| Add authorization                | `app/policies/` — inherit from `ApplicationPolicy`, implement `permission_resource`              |
| Add a Stimulus controller        | `app/javascript/controllers/{name}_controller.js` (auto-registered)                              |
| Add a JS library                 | `vendor/javascript/`, `config/importmap.rb`, `app/assets/config/manifest.js`                     |
| Change layout/nav                | `app/views/layouts/dashboard/` (`application.html.erb`, `_sidebar.html.erb`, `_navbar.html.erb`) |
| Add flash messages to modal form | Add `format.turbo_stream` response + `.turbo_stream.erb` view                                    |
| Add audit logging                | Include `Auditable` concern or call `log_audit` directly                                         |
| Modify CSS                       | `app/assets/stylesheets/` (SCSS files, imports Bootstrap)                                        |

---

## Architecture Mental Model

```
USER (Browser)
  │
  │  Turbo Drive (SPA-like navigation)
  │  Turbo Frames (modal content, partial updates)
  │  Turbo Streams (flash messages, table refreshes)
  │
  ▼
RAILS APP
  │
  ├── Devise ──────── Authentication (session-based)
  ├── Pundit ──────── Authorization (permission code checks)
  ├── Controllers ─── Business logic + audit logging
  ├── Models ──────── Validations + associations + soft deletes
  ├── Policies ────── Permission checks + scope filtering
  └── Views ───────── ERB + Turbo Frame/Stream responses
  │
  ▼
PostgreSQL (single database, multi-tenant via scoping)
```

---

## Domain Model

### Core Entities

```
Company (client org)
  ├── has_many Users (client team members)
  └── has_many Projects (BI project containers)
        └── has_many Dashboards (embedded BI reports)
              └── HABTM Users (explicit access assignment)

Role
  └── has_many Permissions (through RolesPermission)

User
  ├── belongs_to Role
  ├── belongs_to Company (optional — Superadmins have no company)
  └── HABTM Dashboards (what dashboards they can view)

AuditLog
  ├── belongs_to User (who did it)
  └── belongs_to Auditable (polymorphic — what was affected)
```

### Key Invariants

1. **Superadmin users** have `role.name == "Superadmin"` — they bypass ALL permission checks
2. **Client users** must have a `company_id` — enforced by validation
3. **Dashboard access** is per-user, not per-company — even within the same company, users see different dashboards
4. **All major models** use `Discard::Model` for soft deletes (never `destroy`, always `discard`)
5. **Counter caches** (`users_count`, `projects_count`) are maintained with custom callbacks due to soft deletes

---

## Permission System (CRITICAL)

### How it works

Permissions are stored in the `permissions` table with dot-notation codes:

```
Format: {namespace.}{resource}.{action}

Examples:
  dashboard.index
  projects.index / projects.show / projects.create / projects.update / projects.destroy
  bi_dashboards.index / bi_dashboards.show
  user_management.users.index / user_management.users.create
  user_management.roles.index / user_management.roles.update
  company_management.companies.index / company_management.companies.update
  audit_logs.index / audit_logs.show
```

### Authorization check chain

```ruby
# In controller:
authorize Project            # Calls ProjectPolicy#index? (for collection actions)
authorize @project           # Calls ProjectPolicy#show? (for instance actions)
policy_scope(Project)        # Calls ProjectPolicy::Scope#resolve (filtered records)

# In ApplicationPolicy (base):
def index?
  user.has_permission?(build_permission_code("index"))
  # build_permission_code calls permission_resource (abstract) + ".index"
end

# In User model:
def has_permission?(code)
  return false unless role
  return true if superadmin?      # ← Superadmin bypass
  permission_codes.include?(code) # ← Cached lookup
end
```

### Adding a new permission-protected resource

1. Define permissions in `db/seeds.rb`:
   ```ruby
   { code: 'things.index', name: 'List', resource: 'things', section: 'Things' }
   ```
2. Create policy:

   ```ruby
   class ThingPolicy < ApplicationPolicy
     private
     def permission_resource = "things"

     class Scope < ApplicationPolicy::Scope
       private
       def permission_resource = "things"
       def apply_role_based_scope = scope.where(company: user.company)
     end
   end
   ```

3. In controller: `authorize Thing` and `policy_scope(Thing)`
4. In sidebar: `<% if can_view_menu?("things.index") %>`

---

## Controller Conventions

### Standard CRUD Pattern

Every controller follows this exact pattern:

```ruby
class ThingsController < ApplicationController
  include Auditable                    # Optional audit DSL
  before_action :set_thing, only: %i[show edit update destroy confirm_delete]

  def index
    authorize Thing                    # Pundit check
    @q = policy_scope(Thing)           # Scoped by role
            .kept                      # Exclude soft-deleted
            .ransack(params[:q])       # Search/filter
    @q.sorts = "created_at desc" if @q.sorts.empty?
    @pagy, @things = pagy(@q.result.includes(:association))  # Paginate
  end

  def create
    authorize Thing
    @thing = Thing.new(thing_params)
    if @thing.save
      audit_create(@thing, module_name: "things")
      reload_things_list              # Refresh data for turbo_stream
      respond_to do |format|
        format.html { redirect_to things_path, notice: "Created." }
        format.turbo_stream           # Renders create.turbo_stream.erb
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @thing.discard                     # Soft delete (NOT destroy)
    audit_delete(@thing, module_name: "things")
    reload_things_list
    respond_to do |format|
      format.html { redirect_to things_path, notice: "Deleted." }
      format.turbo_stream
    end
  end

  private
  def set_thing
    @thing = Thing.kept.find(params[:id])  # .kept = not soft-deleted
    authorize @thing
  end

  def reload_things_list                   # For turbo_stream responses
    @q = policy_scope(Thing).kept.ransack(params[:q])
    @q.sorts = "created_at desc" if @q.sorts.empty?
    @pagy, @things = pagy(@q.result.includes(:association))
  end
end
```

### Turbo Stream Response Pattern

When a form is inside a `turbo_frame_tag "modal"`, redirects won't update flash messages (they're outside the frame). Use turbo_stream:

```erb
<%# app/views/things/create.turbo_stream.erb %>

<%# 1. Refresh table body %>
<%= turbo_stream.replace "things-table-body" do %>
  <%= render partial: "thing_row", collection: @things, as: :thing %>
<% end %>

<%# 2. Show flash message %>
<%= turbo_stream.update "flash-messages" do %>
  <%= render "layouts/flash" %>
<% end %>

<%# 3. Close modal %>
<%= turbo_stream.append "modal" do %>
  <script>
    const modal = document.getElementById('mainModal');
    if (modal) {
      const instance = bootstrap.Modal.getInstance(modal);
      if (instance) instance.hide();
    }
  </script>
<% end %>
```

---

## Frontend Architecture

### JavaScript Module System

**No Node.js, no bundler, no webpack.** Uses `importmap-rails` for native browser ESM:

```ruby
# config/importmap.rb
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "bootstrap", to: "https://cdn.jsdelivr.net/npm/bootstrap@5.3.5/dist/js/bootstrap.esm.min.js"
pin "@popperjs/core", to: "https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.8/dist/esm/popper.min.js"
pin "tom-select", to: "tom-select.js"  # Vendored in vendor/javascript/
```

### Adding a New JS Library

1. Download self-contained ESM bundle:
   ```bash
   curl -L -o vendor/javascript/lib.js "https://esm.sh/lib-name@version?bundle-deps"
   ```
2. Register in `config/importmap.rb`:
   ```ruby
   pin "lib-name", to: "lib.js"
   ```
3. Ensure `vendor/javascript` is linked in `app/assets/config/manifest.js`:
   ```javascript
   //= link_tree ../../../vendor/javascript .js
   ```
4. Import in your Stimulus controller:
   ```javascript
   import LibName from "lib-name";
   ```

**IMPORTANT**: Only ESM bundles work. UMD/CJS will fail. Use `esm.sh` with `?bundle-deps` for self-contained ESM.

### Stimulus Controllers

Located in `app/javascript/controllers/`. Auto-registered via `eagerLoadControllersFrom`.

| Controller    | Purpose                             | Key Pattern                                                |
| ------------- | ----------------------------------- | ---------------------------------------------------------- |
| `modal`       | Bootstrap modal + Turbo Frame       | Registers `hidden.bs.modal` to clear frame content         |
| `sidebar`     | Toggle sidebar, mobile support      | Listens for `turbo:load` and `turbo:render`                |
| `tom-select`  | Multi-select combo box              | Values: `placeholder`, `maxItems`; plugin: `remove_button` |
| `search-form` | Submit search on input              | Debounced form submission                                  |
| `multi-sort`  | Ransack multi-column sort           | Dynamic sort field management                              |
| `icon-toggle` | Bootstrap icon / file upload switch | Toggles visibility of icon sections                        |
| `user-form`   | Dynamic company field               | Shows/hides company based on role                          |

### Layout Structure

```erb
<!-- app/views/layouts/dashboard/application.html.erb -->
<body>
  <nav><!-- _navbar.html.erb --></nav>
  <div class="d-flex">
    <aside><!-- _sidebar.html.erb (permission-guarded links) --></aside>
    <main>
      <div id="flash-messages"><!-- _flash.html.erb --></div>
      <%= yield %>
    </main>
  </div>
</body>
```

The `"flash-messages"` div ID is the target for Turbo Stream flash updates.

---

## Database

### Schema Key Points

- PostgreSQL 16.1 running in Docker
- All timestamps are `datetime` (with timezone via PostgreSQL)
- Soft deletes: `discarded_at` column on Company, Project, Dashboard, User, Role, Permission, RolesPermission
- Counter caches: `Company#users_count`, `Company#projects_count`
- HABTM join table: `dashboards_users` (no model, no primary key)
- JSONB columns: `AuditLog#data_before`, `AuditLog#data_after`, `AuditLog#metadata`
- Active Storage tables: `active_storage_blobs`, `active_storage_attachments`, `active_storage_variant_records`

### database.yml Notes

- Development: connects to Docker `db` service via env vars
- Production: uses `ENV["DATABASE_URL"]` (NOT `ENV.fetch` — that raises in dev)
- All sections are ERB-parsed regardless of `RAILS_ENV`

### Running Migrations

```bash
docker compose exec web rails db:migrate
docker compose exec web rails db:seed    # Dev only (blocked in production)
```

---

## Routing Rules

```ruby
# Soft delete restore concern (used by projects, companies, dashboards, users, roles)
concern :restorable do
  member { patch :restore }
end

# Key routes:
root "dashboard#index"                     # → DashboardController#index
resource :profile, only: [:show, :edit, :update]  # Singular resource
resources :bi_dashboards, only: [:index, :show]    # Client dashboard viewer
resources :projects, concerns: :restorable do      # Nested dashboards
  resources :dashboards, except: %i[index show], concerns: :restorable
end
resources :companies, concerns: :restorable        # + assign_users, update_users, remove_user
namespace :user_management do                      # Namespaced admin
  resources :users, concerns: :restorable
  resources :roles, concerns: :restorable
end
resources :audit_logs, only: %i[index show]        # Read-only
```

---

## Audit Logging

### Two approaches exist:

1. **`Auditable` concern** (preferred for CRUD):

   ```ruby
   include Auditable
   audit_create(@record, module_name: "module_name")
   audit_update(@record, module_name: "module_name") { @record.update(params) }
   audit_delete(@record, module_name: "module_name")
   ```

2. **Direct `log_audit`** (from ApplicationController, for custom events):
   ```ruby
   log_audit(
     action: "update",
     module_name: "company_management",
     auditable: @company,
     summary: "Updated company: #{@company.name}",
     data_before: data_before,
     data_after: @company.attributes
   )
   ```

### AuditLog Actions

```ruby
AuditLog::ACTIONS = %w[create update delete login logout view export]
```

---

## Testing

### Structure

```
test/
├── controllers/     # Request-level controller tests
├── models/          # Model unit tests (validations, scopes, methods)
├── integration/     # Multi-step workflow tests
├── system/          # Browser tests (Capybara + Selenium)
├── helpers/         # Helper method tests
└── fixtures/        # YAML fixtures
```

### Running Tests

```bash
docker compose exec web rails test           # Unit + integration
docker compose exec web rails test:system    # Browser tests
docker compose exec web rails test test/models/user_test.rb  # Single file
```

---

## CI/CD Pipeline

### Continuous Integration (on every PR and push to main)

```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐
│  scan_ruby  │  │   scan_js   │  │    test     │  │ system-test  │
│  Brakeman + │  │  importmap  │  │  Rails unit │  │  Browser     │
│  bundler-   │  │  audit      │  │  tests      │  │  tests       │
│  audit      │  │             │  │  (Postgres) │  │  (Postgres)  │
└─────────────┘  └─────────────┘  └─────────────┘  └──────────────┘
```

### Continuous Deployment (on push to main, after CI)

```
cd-build.yml: Build Docker image → Push to ghcr.io/{repo}:latest
      │
      ▼
cd-deploy.yml: SSH to production → docker compose pull → up -d → db:migrate
      │
      ├─ Slack notification (start)
      ├─ Health check (30 retries × 5s)
      └─ Slack notification (result + duration)
```

---

## Common Pitfalls

### 1. Turbo Frame Traps Flash Messages

**Problem**: Forms inside `turbo_frame_tag "modal"` — redirect only updates frame, not flash messages.
**Solution**: Add `format.turbo_stream` response that explicitly updates `#flash-messages`.

### 2. Permission Cache Staleness

**Problem**: Changing role permissions doesn't immediately affect logged-in users.
**How it works**: `User#permission_codes` uses composite memoization key (`user_id + role_id + role.updated_at`). `RolesPermission` has `belongs_to :role, touch: true` which bumps `role.updated_at`.

### 3. Infinite Redirect Loops

**Problem**: User with limited permissions gets stuck in redirect loop.
**Root cause**: `first_accessible_path` returns a path the user can't access.
**Solution**: `User#first_accessible_path` checks permissions in priority order, falls back to `:profile_path` (always accessible).

### 4. importmap ESM Requirement

**Problem**: `pin "lib", to: "lib.umd.js"` fails silently.
**Root cause**: importmap only supports ESM. UMD/CJS modules don't export correctly.
**Solution**: Use `esm.sh` with `?bundle-deps` for self-contained ESM bundles.

### 5. database.yml ERB in Wrong Environment

**Problem**: `ENV.fetch("DATABASE_URL")` in production section crashes in development.
**Root cause**: ERB processes ALL YAML sections regardless of `RAILS_ENV`.
**Solution**: Use `ENV["DATABASE_URL"]` (returns nil) instead of `ENV.fetch` (raises).

### 6. Soft Delete Counter Cache Drift

**Problem**: `Company#users_count` becomes inaccurate after soft deletes.
**Root cause**: Rails `counter_cache: true` doesn't know about soft deletes.
**Solution**: Custom `after_discard`/`after_undiscard` callbacks on User and Project.

### 7. N+1 Queries in Sidebar

**Problem**: Sidebar calls `has_permission?` many times, each querying permissions.
**Solution**: `ApplicationController#eager_load_user_permissions` preloads `{ role: :permissions }` on every request.

---

## Code Style & Conventions

### Ruby

- **Frozen string literals**: All `.rb` files start with `# frozen_string_literal: true`
- **RuboCop**: Rails Omakase style, auto-corrected on pre-push hook
- **Strong params**: Always use `params.require(:model).permit(...)`
- **Soft delete**: Use `@record.discard` not `@record.destroy`
- **Query scoping**: Always use `policy_scope(Model).kept` for listings
- **Naming**: snake_case for files/methods, CamelCase for classes

### JavaScript

- **ES Modules only** (no CommonJS `require()`)
- **Stimulus conventions**: `{name}_controller.js`, values/targets/actions pattern
- **No jQuery** — use vanilla JS or Stimulus
- **Bootstrap via ESM CDN**: `window.bootstrap` is set globally in `application.js`

### Views

- **ERB** (not Haml/Slim)
- **Turbo Frames** for modal content: wrap with `turbo_frame_tag "modal"`
- **Turbo Streams** for in-place updates: `.turbo_stream.erb` templates
- **Partials**: `_form.html.erb`, `_{model}_row.html.erb`, `_modal.html.erb`
- **Flash patterns**: Use `flash[:notice]` for success, `flash[:alert]` for errors

### Policies

- Always inherit from `ApplicationPolicy`
- Override `permission_resource` method (string like `"projects"` or `"user_management.users"`)
- Custom Scope: override `apply_role_based_scope` for non-superadmin filtering
- Never check `superadmin?` in policy methods — it's handled by `User#has_permission?`

---

## Seed Data Default Credentials

| Role                | Email                         | Password      |
| ------------------- | ----------------------------- | ------------- |
| Superadmin          | `superadmin@example.com`      | `password123` |
| Client (Acme)       | `john.doe@acme.com`           | `password123` |
| Client (TechVision) | `alice.chen@techvision.com`   | `password123` |
| Client (DataFlow)   | `sarah.williams@dataflow.com` | `password123` |

---

## Environment Setup

```bash
# Clone and start
git clone <repo-url>
cd st_insight_hub
cp .env.example .env       # Configure environment variables
docker compose up -d        # Start PostgreSQL + Rails
docker compose exec web rails db:create db:migrate db:seed

# Access
open http://localhost:3000  # Login with superadmin@example.com / password123

# Development
docker compose exec web rails console   # Rails console
docker compose exec web rails test      # Run tests
docker compose logs -f web              # Follow logs
```

---

## File Modification Checklist

When an AI agent modifies this codebase, verify:

- [ ] `# frozen_string_literal: true` at top of all Ruby files
- [ ] Pundit `authorize` call in every controller action
- [ ] `policy_scope` used for collection queries (not raw `Model.all`)
- [ ] `.kept` scope applied to exclude soft-deleted records
- [ ] Audit logging for all CUD operations
- [ ] `format.turbo_stream` added if form is in a Turbo Frame modal
- [ ] New permissions added to `db/seeds.rb` if new resource
- [ ] Sidebar link guarded with `can_view_menu?("resource.index")`
- [ ] No `ENV.fetch` in production section of `database.yml`
- [ ] JS imports use ESM (no `require()`)
