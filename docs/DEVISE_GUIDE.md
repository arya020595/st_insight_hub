# 🔐 Devise Authentication Guide

## What is Devise?

Devise is a flexible authentication solution for Rails applications. It handles user registration, login, logout, password reset, account confirmation, and more - all out of the box.

---

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Installation & Setup](#installation--setup)
3. [How Devise Works](#how-devise-works)
4. [Customizing Views](#customizing-views)
5. [Customizing Controllers](#customizing-controllers)
6. [Configuration](#configuration)
7. [Common Use Cases](#common-use-cases)
8. [Authentication Helpers](#authentication-helpers)
9. [Authorization with Pundit](#authorization-with-pundit)
10. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### 🏗️ Devise Structure in Our App

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEVISE ARCHITECTURE                          │
└─────────────────────────────────────────────────────────────────┘

USER REQUEST
    │
    ↓
┌─────────────────────────────────────────────────────────────────┐
│  ROUTES (config/routes.rb)                                      │
│                                                                 │
│  devise_for :users, controllers: {                              │
│    sessions: 'users/sessions',                                  │
│    registrations: 'users/registrations',                        │
│    passwords: 'users/passwords'                                 │
│  }                                                              │
└─────────────────────────────────────────────────────────────────┘
    │
    ↓
┌─────────────────────────────────────────────────────────────────┐
│  CONTROLLERS (app/controllers/users/)                           │
│                                                                 │
│  ├── sessions_controller.rb       (Sign in/out)                │
│  ├── registrations_controller.rb  (Sign up/edit profile)       │
│  ├── passwords_controller.rb      (Forgot/reset password)      │
│  ├── confirmations_controller.rb  (Email confirmation)         │
│  ├── unlocks_controller.rb        (Account unlock)             │
│  └── omniauth_callbacks_controller.rb (OAuth - Google, etc.)   │
│                                                                 │
│  All inherit from Devise::*Controller                           │
└─────────────────────────────────────────────────────────────────┘
    │
    ↓
┌─────────────────────────────────────────────────────────────────┐
│  VIEWS (app/views/devise/)                                      │
│                                                                 │
│  ├── sessions/                                                  │
│  │   └── new.html.erb           (Sign in page)                 │
│  ├── registrations/                                             │
│  │   ├── new.html.erb           (Sign up page)                 │
│  │   └── edit.html.erb          (Edit profile)                 │
│  ├── passwords/                                                 │
│  │   ├── new.html.erb           (Forgot password)              │
│  │   └── edit.html.erb          (Reset password)               │
│  └── shared/                                                    │
│      ├── _error_messages.html.erb                              │
│      └── _links.html.erb                                        │
└─────────────────────────────────────────────────────────────────┘
    │
    ↓
┌─────────────────────────────────────────────────────────────────┐
│  MODEL (app/models/user.rb)                                     │
│                                                                 │
│  class User < ApplicationRecord                                 │
│    devise :database_authenticatable, :registerable,             │
│           :recoverable, :rememberable, :validatable,            │
│           :trackable                                            │
│                                                                 │
│    # Associations                                               │
│    belongs_to :role                                             │
│    has_many :work_orders                                        │
│  end                                                            │
└─────────────────────────────────────────────────────────────────┘
    │
    ↓
┌─────────────────────────────────────────────────────────────────┐
│  DATABASE (db/schema.rb)                                        │
│                                                                 │
│  create_table "users" do |t|                                    │
│    t.string   "email",                default: "", null: false  │
│    t.string   "encrypted_password",   default: "", null: false  │
│    t.string   "reset_password_token"                            │
│    t.datetime "reset_password_sent_at"                          │
│    t.datetime "remember_created_at"                             │
│    t.integer  "sign_in_count",         default: 0               │
│    t.datetime "current_sign_in_at"                              │
│    t.datetime "last_sign_in_at"                                 │
│    t.string   "current_sign_in_ip"                              │
│    t.string   "last_sign_in_ip"                                 │
│    # ... custom fields                                          │
│  end                                                            │
└─────────────────────────────────────────────────────────────────┘
```

---

## Installation & Setup

### 1️⃣ Initial Installation (Already Done)

```bash
# Add to Gemfile
gem 'devise'

# Install
bundle install

# Generate Devise configuration
rails generate devise:install

# Generate User model
rails generate devise User

# Run migrations
rails db:migrate
```

### 2️⃣ Generate Custom Views (Already Done)

```bash
# Generate all Devise views
docker compose exec web rails generate devise:views
```

**Generated files:**

```
app/views/devise/
├── confirmations/
│   └── new.html.erb
├── mailer/
│   ├── confirmation_instructions.html.erb
│   ├── email_changed.html.erb
│   ├── password_change.html.erb
│   ├── reset_password_instructions.html.erb
│   └── unlock_instructions.html.erb
├── passwords/
│   ├── edit.html.erb
│   └── new.html.erb
├── registrations/
│   ├── edit.html.erb
│   └── new.html.erb
├── sessions/
│   └── new.html.erb
├── shared/
│   ├── _error_messages.html.erb
│   └── _links.html.erb
└── unlocks/
    └── new.html.erb
```

### 3️⃣ Generate Custom Controllers (Already Done)

```bash
# Generate all Devise controllers
docker compose exec web rails generate devise:controllers users
```

**Generated files:**

```
app/controllers/users/
├── confirmations_controller.rb
├── omniauth_callbacks_controller.rb
├── passwords_controller.rb
├── registrations_controller.rb
├── sessions_controller.rb
└── unlocks_controller.rb
```

### 4️⃣ Configure Routes (Already Done)

```ruby
# config/routes.rb
Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    passwords: 'users/passwords',
    confirmations: 'users/confirmations',
    unlocks: 'users/unlocks',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  root "dashboard#index"

  # ... other routes
end
```

---

## How Devise Works

### 🔄 Authentication Flow

#### Sign In Flow

```
1️⃣  User visits /users/sign_in
    │
    ↓
2️⃣  Routes to Users::SessionsController#new
    │
    ↓
3️⃣  Renders app/views/devise/sessions/new.html.erb
    │
    ↓
4️⃣  User submits form (POST /users/sign_in)
    │
    ↓
5️⃣  Routes to Users::SessionsController#create
    │
    ↓
6️⃣  Devise validates credentials
    │
    ├──► ✅ Valid → Sign in user, redirect to after_sign_in_path
    │
    └──► ❌ Invalid → Show error, re-render sign in page
```

#### Sign Up Flow

```
1️⃣  User visits /users/sign_up
    │
    ↓
2️⃣  Routes to Users::RegistrationsController#new
    │
    ↓
3️⃣  Renders app/views/devise/registrations/new.html.erb
    │
    ↓
4️⃣  User submits form (POST /users)
    │
    ↓
5️⃣  Routes to Users::RegistrationsController#create
    │
    ↓
6️⃣  Devise validates user data
    │
    ├──► ✅ Valid → Create user, sign in, redirect
    │
    └──► ❌ Invalid → Show errors, re-render sign up page
```

### 📍 Devise Routes

All routes generated by `devise_for :users`:

```bash
# List all Devise routes
docker compose exec web rails routes | grep devise
```

**Main routes:**

| HTTP Method | Path                   | Controller#Action     | Purpose             |
| ----------- | ---------------------- | --------------------- | ------------------- |
| GET         | `/users/sign_in`       | sessions#new          | Sign in page        |
| POST        | `/users/sign_in`       | sessions#create       | Submit sign in      |
| DELETE      | `/users/sign_out`      | sessions#destroy      | Sign out            |
| GET         | `/users/sign_up`       | registrations#new     | Sign up page        |
| POST        | `/users`               | registrations#create  | Submit sign up      |
| GET         | `/users/edit`          | registrations#edit    | Edit profile        |
| PATCH/PUT   | `/users`               | registrations#update  | Update profile      |
| DELETE      | `/users`               | registrations#destroy | Delete account      |
| GET         | `/users/password/new`  | passwords#new         | Forgot password     |
| POST        | `/users/password`      | passwords#create      | Send reset email    |
| GET         | `/users/password/edit` | passwords#edit        | Reset password page |
| PATCH/PUT   | `/users/password`      | passwords#update      | Submit new password |

---

## Customizing Views

### 🎨 Editing the Sign In Page

**File:** `app/views/devise/sessions/new.html.erb`

```erb
<h2>Log in</h2>

<%= form_for(resource, as: resource_name, url: session_path(resource_name)) do |f| %>
  <div class="field">
    <%= f.label :email %><br />
    <%= f.email_field :email, autofocus: true, autocomplete: "email" %>
  </div>

  <div class="field">
    <%= f.label :password %><br />
    <%= f.password_field :password, autocomplete: "current-password" %>
  </div>

  <% if devise_mapping.rememberable? %>
    <div class="field">
      <%= f.check_box :remember_me %>
      <%= f.label :remember_me %>
    </div>
  <% end %>

  <div class="actions">
    <%= f.submit "Log in" %>
  </div>
<% end %>

<%= render "devise/shared/links" %>
```

### 💅 Adding Bootstrap Styling

```erb
<div class="container">
  <div class="row justify-content-center">
    <div class="col-md-6">
      <div class="card mt-5">
        <div class="card-header">
          <h2>Log in</h2>
        </div>
        <div class="card-body">
          <%= form_for(resource, as: resource_name, url: session_path(resource_name)) do |f| %>
            <div class="mb-3">
              <%= f.label :email, class: "form-label" %>
              <%= f.email_field :email, autofocus: true, autocomplete: "email", class: "form-control" %>
            </div>

            <div class="mb-3">
              <%= f.label :password, class: "form-label" %>
              <%= f.password_field :password, autocomplete: "current-password", class: "form-control" %>
            </div>

            <% if devise_mapping.rememberable? %>
              <div class="form-check mb-3">
                <%= f.check_box :remember_me, class: "form-check-input" %>
                <%= f.label :remember_me, class: "form-check-label" %>
              </div>
            <% end %>

            <div class="d-grid">
              <%= f.submit "Log in", class: "btn btn-primary" %>
            </div>
          <% end %>

          <div class="mt-3">
            <%= render "devise/shared/links" %>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
```

### 🔗 Shared Links Partial

**File:** `app/views/devise/shared/_links.html.erb`

```erb
<%- if controller_name != 'sessions' %>
  <%= link_to "Log in", new_session_path(resource_name) %><br />
<% end %>

<%- if devise_mapping.registerable? && controller_name != 'registrations' %>
  <%= link_to "Sign up", new_registration_path(resource_name) %><br />
<% end %>

<%- if devise_mapping.recoverable? && controller_name != 'passwords' && controller_name != 'registrations' %>
  <%= link_to "Forgot your password?", new_password_path(resource_name) %><br />
<% end %>

<%- if devise_mapping.confirmable? && controller_name != 'confirmations' %>
  <%= link_to "Didn't receive confirmation instructions?", new_confirmation_path(resource_name) %><br />
<% end %>

<%- if devise_mapping.lockable? && resource_class.unlock_strategy_enabled?(:email) && controller_name != 'unlocks' %>
  <%= link_to "Didn't receive unlock instructions?", new_unlock_path(resource_name) %><br />
<% end %>

<%- if devise_mapping.omniauthable? %>
  <%- resource_class.omniauth_providers.each do |provider| %>
    <%= button_to "Sign in with #{OmniAuth::Utils.camelize(provider)}", omniauth_authorize_path(resource_name, provider), data: { turbo: false } %><br />
  <% end %>
<% end %>
```

---

## Customizing Controllers

### 🎯 Sessions Controller (Sign In/Out)

**File:** `app/controllers/users/sessions_controller.rb`

```ruby
class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /users/sign_in
  def new
    super
  end

  # POST /users/sign_in
  def create
    super do |resource|
      # Custom logic after successful sign in
      Rails.logger.info "User #{resource.email} signed in at #{Time.current}"

      # Track login in your own table
      # LoginLog.create(user: resource, ip: request.remote_ip)

      # Set additional session data
      # session[:role] = resource.role.name
    end
  end

  # DELETE /users/sign_out
  def destroy
    Rails.logger.info "User #{current_user.email} signed out"
    super
  end

  protected

  # Override after_sign_in_path
  def after_sign_in_path_for(resource)
    dashboard_path
  end

  # Override after_sign_out_path
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
```

### 👤 Registrations Controller (Sign Up/Edit Profile)

**File:** `app/controllers/users/registrations_controller.rb`

```ruby
class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  # GET /users/sign_up
  def new
    super
  end

  # POST /users
  def create
    super do |resource|
      if resource.persisted?
        # Custom logic after successful registration
        Rails.logger.info "New user registered: #{resource.email}"

        # Assign default role
        resource.update(role: Role.find_by(name: 'Clerk'))

        # Send welcome email
        # UserMailer.welcome_email(resource).deliver_later
      end
    end
  end

  # GET /users/edit
  def edit
    super
  end

  # PATCH/PUT /users
  def update
    super
  end

  # DELETE /users
  def destroy
    super
  end

  protected

  # Permit additional parameters for sign up
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :phone_number])
  end

  # Permit additional parameters for account update
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :phone_number])
  end

  # Override after_sign_up_path
  def after_sign_up_path_for(resource)
    dashboard_path
  end

  # Override after_update_path
  def after_update_path_for(resource)
    edit_user_registration_path
  end
end
```

### 🔑 Passwords Controller (Forgot/Reset Password)

**File:** `app/controllers/users/passwords_controller.rb`

```ruby
class Users::PasswordsController < Devise::PasswordsController
  # GET /users/password/new
  def new
    super
  end

  # POST /users/password
  def create
    super do |resource|
      if successfully_sent?(resource)
        Rails.logger.info "Password reset email sent to #{resource.email}"
      end
    end
  end

  # GET /users/password/edit?reset_password_token=xxx
  def edit
    super
  end

  # PATCH/PUT /users/password
  def update
    super do |resource|
      if resource.errors.empty?
        Rails.logger.info "Password successfully reset for #{resource.email}"
      end
    end
  end

  protected

  def after_resetting_password_path_for(resource)
    new_user_session_path
  end
end
```

---

## Configuration

### 🔧 Devise Configuration

**File:** `config/initializers/devise.rb`

```ruby
Devise.setup do |config|
  # ==> Mailer Configuration
  config.mailer_sender = 'noreply@intentharvest.com'

  # ==> ORM configuration
  require 'devise/orm/active_record'

  # ==> Authentication keys
  config.authentication_keys = [:email]

  # ==> Case insensitive keys
  config.case_insensitive_keys = [:email]

  # ==> Strip whitespace
  config.strip_whitespace_keys = [:email]

  # ==> Password length
  config.password_length = 6..128

  # ==> Timeout
  config.timeout_in = 30.minutes

  # ==> Rememberable
  config.remember_for = 2.weeks

  # ==> Sign out behavior
  config.sign_out_via = :delete

  # ==> Navigational formats
  config.navigational_formats = ['*/*', :html, :turbo_stream]
end
```

### 📧 Email Configuration

**File:** `config/environments/development.rb`

```ruby
config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: 'smtp.gmail.com',
  port: 587,
  user_name: ENV['GMAIL_USERNAME'],
  password: ENV['GMAIL_PASSWORD'],
  authentication: 'plain',
  enable_starttls_auto: true
}
```

---

## Common Use Cases

### 1️⃣ Require Authentication

**In Controller:**

```ruby
class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    # Only accessible by signed-in users
  end
end
```

**In Routes:**

```ruby
# Protect specific routes
authenticate :user do
  resources :work_orders
end

# Public routes
root "pages#home"
```

### 2️⃣ Check if User is Signed In

**In Controller:**

```ruby
if user_signed_in?
  # User is logged in
  current_user.email
else
  # User is not logged in
  redirect_to new_user_session_path
end
```

**In View:**

```erb
<% if user_signed_in? %>
  <p>Welcome, <%= current_user.email %>!</p>
  <%= link_to "Sign out", destroy_user_session_path, method: :delete %>
<% else %>
  <%= link_to "Sign in", new_user_session_path %>
<% end %>
```

### 3️⃣ Redirect After Sign In/Out

**In ApplicationController:**

```ruby
class ApplicationController < ActionController::Base
  protected

  def after_sign_in_path_for(resource)
    case resource.role.name
    when 'Superadmin'
      admin_dashboard_path
    when 'Manager'
      manager_dashboard_path
    when 'Field Conductor'
      field_conductor_dashboard_path
    else
      dashboard_path
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end
end
```

### 4️⃣ Skip Authentication for Specific Actions

```ruby
class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home, :about]

  def home
    # Public page
  end

  def about
    # Public page
  end

  def contact
    # Requires authentication
  end
end
```

### 5️⃣ Custom Validation

**In User Model:**

```ruby
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  # Custom validations
  validates :name, presence: true
  validates :phone_number, format: { with: /\A\d{10,15}\z/ }, allow_blank: true

  # Custom password validation
  validate :password_complexity

  private

  def password_complexity
    return if password.blank?

    unless password.match?(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
      errors.add :password, "must include at least one lowercase letter, one uppercase letter, and one digit"
    end
  end
end
```

### 6️⃣ Account Lockable (After Failed Attempts)

**Enable in model:**

```ruby
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :lockable
end
```

**Migration:**

```bash
docker compose exec web rails generate migration AddLockableToUsers \
  failed_attempts:integer \
  unlock_token:string \
  locked_at:datetime

docker compose exec web rails db:migrate
```

**Configure in `config/initializers/devise.rb`:**

```ruby
config.lock_strategy = :failed_attempts
config.unlock_keys = [:email]
config.unlock_strategy = :both # Email and time
config.maximum_attempts = 5
config.unlock_in = 1.hour
```

### 7️⃣ Email Confirmable (Verify Email)

**Enable in model:**

```ruby
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :confirmable
end
```

**Migration:**

```bash
docker compose exec web rails generate migration AddConfirmableToUsers \
  confirmation_token:string \
  confirmed_at:datetime \
  confirmation_sent_at:datetime \
  unconfirmed_email:string

docker compose exec web rails db:migrate
```

---

## Authentication Helpers

### Available Helpers

| Helper                   | Description                               |
| ------------------------ | ----------------------------------------- |
| `user_signed_in?`        | Returns true if user is signed in         |
| `current_user`           | Returns the current signed-in user        |
| `user_session`           | Returns the user's session data           |
| `authenticate_user!`     | Redirects to sign in if not authenticated |
| `sign_in(@user)`         | Manually sign in a user                   |
| `sign_out(current_user)` | Manually sign out a user                  |
| `bypass_sign_in(@user)`  | Sign in without running callbacks         |

### Usage Examples

**In Controller:**

```ruby
class WorkOrdersController < ApplicationController
  before_action :authenticate_user!

  def index
    # current_user is available here
    @work_orders = current_user.work_orders
  end

  def create
    @work_order = current_user.work_orders.build(work_order_params)
    if @work_order.save
      redirect_to @work_order
    else
      render :new
    end
  end
end
```

**In View:**

```erb
<% if user_signed_in? %>
  <div class="user-info">
    <p>Logged in as: <%= current_user.email %></p>
    <p>Role: <%= current_user.role.name %></p>
    <%= link_to "Sign out", destroy_user_session_path,
        data: { turbo_method: :delete },
        class: "btn btn-danger" %>
  </div>
<% else %>
  <%= link_to "Sign in", new_user_session_path, class: "btn btn-primary" %>
<% end %>
```

---

## Authorization with Pundit

While Devise handles **authentication** (who you are), Pundit handles **authorization** (what you can do).

### Integration Example

**In Controller:**

```ruby
class WorkOrdersController < ApplicationController
  before_action :authenticate_user!  # Devise

  def index
    @work_orders = policy_scope(WorkOrder)  # Pundit
  end

  def show
    @work_order = WorkOrder.find(params[:id])
    authorize @work_order  # Pundit
  end

  def create
    @work_order = WorkOrder.new(work_order_params)
    authorize @work_order  # Pundit

    if @work_order.save
      redirect_to @work_order
    else
      render :new
    end
  end
end
```

**Policy:**

```ruby
class WorkOrderPolicy < ApplicationPolicy
  def index?
    user.present?  # Must be signed in (Devise provides user)
  end

  def show?
    user.role.name == 'Superadmin' ||
    user.role.name == 'Manager' ||
    record.field_conductor_id == user.id
  end

  def create?
    user.role.name.in?(['Superadmin', 'Field Conductor'])
  end
end
```

---

## Troubleshooting

### 🔴 "You need to sign in or sign up before continuing"

**Problem:** Accessing a protected page without authentication.

**Solution:**

```ruby
# Either sign in or skip authentication for that action
class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]
end
```

### 🔴 Invalid Email or Password

**Problem:** Can't sign in with correct credentials.

**Check:**

1. Email is correct (case-insensitive)
2. Password is correct
3. User exists in database:
   ```bash
   docker compose exec web rails console
   User.find_by(email: 'test@example.com')
   ```

### 🔴 Sign Out Not Working

**Problem:** Clicking sign out doesn't work.

**Solution:** Check HTTP method:

```erb
<%# Wrong - uses GET %>
<%= link_to "Sign out", destroy_user_session_path %>

<%# Correct - uses DELETE %>
<%= link_to "Sign out", destroy_user_session_path,
    data: { turbo_method: :delete } %>
```

### 🔴 After Sign In, Redirects to Root

**Problem:** Not redirecting to intended page after sign in.

**Solution:** Override redirect path:

```ruby
# app/controllers/application_controller.rb
def after_sign_in_path_for(resource)
  stored_location_for(resource) || dashboard_path
end
```

### 🔴 CSRF Token Authenticity Error

**Problem:** `ActionController::InvalidAuthenticityToken` error.

**Solution:** Ensure form has CSRF token:

```erb
<%= form_for(resource, as: resource_name, url: session_path(resource_name)) do |f| %>
  <%# CSRF token is automatically included %>
<% end %>
```

### 🔴 Email Not Sending

**Problem:** Password reset or confirmation emails not sending.

**Check configuration:**

```ruby
# config/environments/development.rb
config.action_mailer.perform_deliveries = true
config.action_mailer.raise_delivery_errors = true
config.action_mailer.delivery_method = :smtp
```

**Test in console:**

```ruby
docker compose exec web rails console
UserMailer.reset_password_instructions(User.first, 'token').deliver_now
```

---

## Quick Reference Commands

```bash
# Generate Devise views
docker compose exec web rails generate devise:views

# Generate Devise controllers
docker compose exec web rails generate devise:controllers users

# List all Devise routes
docker compose exec web rails routes | grep devise

# Rails console - check user
docker compose exec web rails console
User.find_by(email: 'admin@example.com')
User.last.valid_password?('password')

# Create user in console
User.create!(
  email: 'test@example.com',
  password: 'password',
  password_confirmation: 'password',
  role: Role.find_by(name: 'Clerk')
)

# Reset user password
user = User.find_by(email: 'admin@example.com')
user.update(password: 'newpassword', password_confirmation: 'newpassword')
```

---

## Summary

### ✅ What We Have

- **Authentication:** Devise handles user sign in/out/registration
- **Custom Views:** All HTML can be customized in `app/views/devise/`
- **Custom Controllers:** All logic can be customized in `app/controllers/users/`
- **Authorization:** Combined with Pundit for role-based access control
- **Auditing:** Audited gem tracks all user changes

### 📂 File Structure

```
app/
├── controllers/
│   ├── application_controller.rb (set_current_user for auditing)
│   └── users/
│       ├── sessions_controller.rb
│       ├── registrations_controller.rb
│       ├── passwords_controller.rb
│       └── ...
├── models/
│   └── user.rb (devise modules, associations, validations)
├── views/
│   └── devise/
│       ├── sessions/new.html.erb (sign in page)
│       ├── registrations/new.html.erb (sign up page)
│       └── ...
└── policies/
    └── application_policy.rb (Pundit authorization)

config/
├── initializers/
│   └── devise.rb (Devise configuration)
└── routes.rb (devise_for :users with custom controllers)

db/
└── migrate/
    └── *_devise_create_users.rb
```

---

**Last Updated:** October 27, 2025  
**Devise Version:** 4.9.4  
**Rails Version:** 8.x
