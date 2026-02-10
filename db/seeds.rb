# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Block seeding in production environment for safety
if Rails.env.production?
  puts '⚠️  SEEDING BLOCKED!'
  puts '─' * 80
  puts ''
  puts 'db:seed is disabled in production environment for security reasons.'
  puts 'Use dedicated rake tasks for production data management instead.'
  puts ''
  puts '─' * 80
  exit 1
end

puts '🌱 Starting seed process...'
puts "📅 Seeding at: #{Time.current}"
puts '─' * 80

# ============================================================================
# PERMISSIONS
# ============================================================================
puts "\n🔐 Creating permissions..."
puts '─' * 80

permission_definitions = [
  # ============================================================================
  # 1. DASHBOARD - Main dashboard page (dashboard_controller.rb)
  # ============================================================================
  { code: 'dashboard.index', name: 'View', resource: 'dashboard', section: 'Dashboard' },

  # ============================================================================
  # 2. PROJECT MANAGEMENT - Projects and BI Dashboards (projects_controller.rb, bi_dashboards_controller.rb)
  # ============================================================================
  # Projects
  { code: 'projects.index', name: 'List', resource: 'projects', section: 'Project Management' },
  { code: 'projects.show', name: 'View', resource: 'projects', section: 'Project Management' },
  { code: 'projects.create', name: 'Create', resource: 'projects', section: 'Project Management' },
  { code: 'projects.update', name: 'Update', resource: 'projects', section: 'Project Management' },
  { code: 'projects.destroy', name: 'Delete', resource: 'projects', section: 'Project Management' },

  # Dashboards (nested within projects)
  { code: 'dashboards.create', name: 'Create', resource: 'dashboards', section: 'Project Management' },
  { code: 'dashboards.update', name: 'Update', resource: 'dashboards', section: 'Project Management' },
  { code: 'dashboards.destroy', name: 'Delete', resource: 'dashboards', section: 'Project Management' },

  # BI Dashboards (viewing embedded dashboards in sidebar)
  { code: 'bi_dashboards.index', name: 'List', resource: 'bi_dashboards', section: 'Project Management' },
  { code: 'bi_dashboards.show', name: 'View', resource: 'bi_dashboards', section: 'Project Management' },

  # ============================================================================
  # 3. USER MANAGEMENT - Users and Roles (user_management/users_controller.rb, user_management/roles_controller.rb)
  # ============================================================================
  # Users
  { code: 'user_management.users.index', name: 'List', resource: 'user_management.users', section: 'User Management' },
  { code: 'user_management.users.show', name: 'View', resource: 'user_management.users', section: 'User Management' },
  { code: 'user_management.users.create', name: 'Create', resource: 'user_management.users', section: 'User Management' },
  { code: 'user_management.users.update', name: 'Update', resource: 'user_management.users', section: 'User Management' },
  { code: 'user_management.users.destroy', name: 'Delete', resource: 'user_management.users', section: 'User Management' },

  # Roles
  { code: 'user_management.roles.index', name: 'List', resource: 'user_management.roles', section: 'User Management' },
  { code: 'user_management.roles.show', name: 'View', resource: 'user_management.roles', section: 'User Management' },
  { code: 'user_management.roles.create', name: 'Create', resource: 'user_management.roles', section: 'User Management' },
  { code: 'user_management.roles.update', name: 'Update', resource: 'user_management.roles', section: 'User Management' },
  { code: 'user_management.roles.destroy', name: 'Delete', resource: 'user_management.roles', section: 'User Management' },

  # ============================================================================
  # 4. AUDIT LOGS - Activity tracking (audit_logs_controller.rb)
  # ============================================================================
  { code: 'audit_logs.index', name: 'List', resource: 'audit_logs', section: 'Audit Logs' },
  { code: 'audit_logs.show', name: 'View', resource: 'audit_logs', section: 'Audit Logs' }
]

permission_definitions.each do |attrs|
  Permission.find_or_create_by!(code: attrs[:code]) do |p|
    p.name = attrs[:name]
    p.resource = attrs[:resource]
    p.section = attrs[:section]
  end
end

puts "✓ Created #{Permission.count} permissions"

# ============================================================================
# ROLES
# ============================================================================
puts "\n👔 Creating roles..."
puts '─' * 80

# Superadmin role (all permissions) - Development team
superadmin = Role.find_or_create_by!(name: 'Superadmin') do |role|
  role.description = 'Full system access - bypasses all permission checks. For development team only.'
end
# Note: Superadmin bypasses permission checks, but assign all for visibility
superadmin.permissions = Permission.all

# Client role - Client users (read-only access to assigned projects)
client = Role.find_or_create_by!(name: 'Client') do |role|
  role.description = 'Client company users - read-only access to assigned projects and dashboards'
end
# Client only has List and View permissions (no audit log access)
client_permissions = Permission.where(code: [
                                       'dashboard.index',
                                       'projects.index',
                                       'projects.show',
                                       'bi_dashboards.index',
                                       'bi_dashboards.show'
                                     ])
client.permissions = client_permissions

puts "✓ Created #{Role.count} roles"

# ============================================================================
# COMPANIES
# ============================================================================
puts "\n🏢 Creating companies..."
puts '─' * 80

company_a = Company.find_or_create_by!(name: 'Acme Corporation') do |company|
  company.description = 'Global technology solutions provider'
  company.status = 'active'
end

company_b = Company.find_or_create_by!(name: 'TechVision Inc') do |company|
  company.description = 'Innovative software development company'
  company.status = 'active'
end

company_c = Company.find_or_create_by!(name: 'DataFlow Solutions') do |company|
  company.description = 'Data analytics and business intelligence'
  company.status = 'active'
end

puts "✓ Created #{Company.count} companies"

# ============================================================================
# USERS
# ============================================================================
puts "\n👤 Creating users..."
puts '─' * 80

# Superadmin - Development team (no company)
superadmin_user = User.find_or_create_by!(email: 'superadmin@example.com') do |user|
  user.name = 'Super Admin'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = superadmin
  user.company = nil
end

# Company A - Client users
client_a1 = User.find_or_create_by!(email: 'john.doe@acme.com') do |user|
  user.name = 'John Doe'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = client
  user.company = company_a
end

client_a2 = User.find_or_create_by!(email: 'jane.smith@acme.com') do |user|
  user.name = 'Jane Smith'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = client
  user.company = company_a
end

client_a3 = User.find_or_create_by!(email: 'bob.wilson@acme.com') do |user|
  user.name = 'Bob Wilson'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = client
  user.company = company_a
end

# Company B - Client users
client_b1 = User.find_or_create_by!(email: 'alice.chen@techvision.com') do |user|
  user.name = 'Alice Chen'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = client
  user.company = company_b
end

client_b2 = User.find_or_create_by!(email: 'mike.johnson@techvision.com') do |user|
  user.name = 'Mike Johnson'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = client
  user.company = company_b
end

# Company C - Client users
client_c1 = User.find_or_create_by!(email: 'sarah.williams@dataflow.com') do |user|
  user.name = 'Sarah Williams'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = client
  user.company = company_c
end

client_c2 = User.find_or_create_by!(email: 'david.brown@dataflow.com') do |user|
  user.name = 'David Brown'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = client
  user.company = company_c
end

client_c3 = User.find_or_create_by!(email: 'emma.davis@dataflow.com') do |user|
  user.name = 'Emma Davis'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = client
  user.company = company_c
end

puts "✓ Created #{User.count} users"

# ============================================================================
# SAMPLE PROJECTS & DASHBOARDS
# ============================================================================
puts "\n📊 Creating sample projects and dashboards..."
puts '─' * 80

project_configs = [
  {
    name: 'Sales Analytics',
    description: 'Sales performance and revenue analytics dashboards',
    icon: 'bi-graph-up',
    status: 'active',
    company: company_a,
    dashboards: [
      { name: 'Sales Overview', embed_url: 'https://example.com/embed/sales-overview', embed_type: 'iframe', status: 'active', users: [ client_a1, client_a2 ] },
      { name: 'Revenue Breakdown', embed_url: 'https://example.com/embed/revenue', embed_type: 'iframe', status: 'active', users: [ client_a1, client_a2 ] }
    ]
  },
  {
    name: 'Marketing Insights',
    description: 'Marketing campaign performance dashboards',
    icon: 'bi-megaphone',
    status: 'active',
    company: company_a,
    dashboards: [
      { name: 'Campaign Performance', embed_url: 'https://example.com/embed/campaigns', embed_type: 'iframe', status: 'active', users: [ client_a1, client_a3 ] },
      { name: 'Social Media Analytics', embed_url: 'https://example.com/embed/social', embed_type: 'iframe', status: 'active', users: [ client_a1, client_a3 ] }
    ]
  },
  {
    name: 'Operations Dashboard',
    description: 'Operational metrics and KPIs',
    icon: 'bi-gear',
    status: 'active',
    company: company_b,
    dashboards: [
      { name: 'KPI Dashboard', embed_url: 'https://example.com/embed/kpi', embed_type: 'iframe', status: 'active', users: [ client_b1, client_b2 ] },
      { name: 'Productivity Metrics', embed_url: 'https://example.com/embed/productivity', embed_type: 'iframe', status: 'active', users: [ client_b1, client_b2 ] }
    ]
  },
  {
    name: 'Customer Insights',
    description: 'Customer behavior and satisfaction analytics',
    icon: 'bi-people',
    status: 'active',
    company: company_c,
    dashboards: [
      { name: 'Customer Satisfaction', embed_url: 'https://example.com/embed/csat', embed_type: 'iframe', status: 'active', users: [ client_c1, client_c2, client_c3 ] },
      { name: 'Churn Analysis', embed_url: 'https://example.com/embed/churn', embed_type: 'iframe', status: 'active', users: [ client_c1, client_c2, client_c3 ] }
    ]
  },
  {
    name: 'Financial Reports',
    description: 'Financial performance and budget tracking',
    icon: 'bi-currency-dollar',
    status: 'active',
    company: company_c,
    dashboards: [
      { name: 'Budget Overview', embed_url: 'https://example.com/embed/budget', embed_type: 'iframe', status: 'active', users: [ client_c1, client_c2 ] },
      { name: 'Expense Tracking', embed_url: 'https://example.com/embed/expenses', embed_type: 'iframe', status: 'active', users: [ client_c1, client_c2 ] }
    ]
  }
]

project_configs.each do |config|
  project = Project.find_or_create_by!(name: config[:name], company_id: config[:company].id) do |p|
    p.description = config[:description]
    p.icon = config[:icon]
    p.status = config[:status]
  end

  config[:dashboards].each_with_index do |dash_config, index|
    dashboard = project.dashboards.find_or_create_by!(name: dash_config[:name]) do |d|
      d.embed_url = dash_config[:embed_url]
      d.embed_type = dash_config[:embed_type]
      d.status = dash_config[:status]
      d.position = index
    end

    # Assign users to dashboard
    dashboard.users = dash_config[:users] if dash_config[:users].present?
  end
end

puts "✓ Created #{Project.count} projects with #{Dashboard.count} dashboards"

# ============================================================================
# FINALIZATION
# ============================================================================
puts "\n🎉 Seeding completed successfully!"
puts '─' * 80
puts "\n📋 Summary:"
puts '─' * 80
puts "\n👔 Roles: #{Role.count}"
puts "   - Superadmin: Full system access (development team)"
puts "   - Client: Read-only access to assigned projects"
puts "\n🏢 Companies: #{Company.count}"
Company.all.each do |company|
  puts "   - #{company.name}: #{company.users.count} users, #{company.projects.count} projects"
end
puts "\n👤 Users: #{User.count}"
puts "   - 1 Superadmin"
puts "   - #{User.joins(:role).where(roles: { name: 'Client' }).count} Client users"
puts "\n📊 Projects: #{Project.count} with #{Dashboard.count} dashboards"
puts "\n🔗 Dashboard Assignments:"

Dashboard.includes(:project, :users).each do |dashboard|
  project_name = dashboard.project&.name || 'No project'
  user_names = dashboard.users.any? ? dashboard.users.pluck(:name).join(', ') : 'No users assigned'
  puts "   - #{dashboard.name} (#{project_name}): #{user_names}"
end

puts "\n" + '─' * 80
puts "\n🔐 Default credentials:"
puts '─' * 80
puts "\n  SUPERADMIN (Development Team - Full Access):"
puts '  📧 Email: superadmin@example.com'
puts '  🔑 Password: password123'
puts ''
puts '  CLIENT - Acme Corporation:'
puts '  📧 Email: john.doe@acme.com, jane.smith@acme.com, bob.wilson@acme.com'
puts '  🔑 Password: password123'
puts '  Projects: Sales Analytics, Marketing Insights'
puts ''
puts '  CLIENT - TechVision Inc:'
puts '  📧 Email: alice.chen@techvision.com, mike.johnson@techvision.com'
puts '  🔑 Password: password123'
puts '  Projects: Operations Dashboard'
puts ''
puts '  CLIENT - DataFlow Solutions:'
puts '  📧 Email: sarah.williams@dataflow.com, david.brown@dataflow.com, emma.davis@dataflow.com'
puts '  🔑 Password: password123'
puts '  Projects: Customer Insights, Financial Reports'
puts '─' * 80
