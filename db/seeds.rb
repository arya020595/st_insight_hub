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
  # Dashboard
  { code: 'dashboard.index', name: 'View Dashboard', resource: 'dashboard', section: 'Dashboard' },

  # BI Dashboards
  { code: 'bi_dashboards.index', name: 'View BI Dashboards', resource: 'bi_dashboards', section: 'BI Dashboards' },

  # Projects (Dashboard Management)
  { code: 'bi_dashboards.projects.index', name: 'View Projects', resource: 'bi_dashboards.projects', section: 'Dashboard Management' },
  { code: 'bi_dashboards.projects.show', name: 'View Project Details', resource: 'bi_dashboards.projects', section: 'Dashboard Management' },
  { code: 'bi_dashboards.projects.create', name: 'Create Project', resource: 'bi_dashboards.projects', section: 'Dashboard Management' },
  { code: 'bi_dashboards.projects.update', name: 'Update Project', resource: 'bi_dashboards.projects', section: 'Dashboard Management' },
  { code: 'bi_dashboards.projects.destroy', name: 'Delete Project', resource: 'bi_dashboards.projects', section: 'Dashboard Management' },

  # User Management - Users
  { code: 'user_management.users.index', name: 'View Users', resource: 'user_management.users', section: 'User Management' },
  { code: 'user_management.users.show', name: 'View User Details', resource: 'user_management.users', section: 'User Management' },
  { code: 'user_management.users.create', name: 'Create User', resource: 'user_management.users', section: 'User Management' },
  { code: 'user_management.users.update', name: 'Update User', resource: 'user_management.users', section: 'User Management' },
  { code: 'user_management.users.destroy', name: 'Delete User', resource: 'user_management.users', section: 'User Management' },

  # User Management - Roles
  { code: 'user_management.roles.index', name: 'View Roles', resource: 'user_management.roles', section: 'User Management' },
  { code: 'user_management.roles.show', name: 'View Role Details', resource: 'user_management.roles', section: 'User Management' },
  { code: 'user_management.roles.create', name: 'Create Role', resource: 'user_management.roles', section: 'User Management' },
  { code: 'user_management.roles.update', name: 'Update Role', resource: 'user_management.roles', section: 'User Management' },
  { code: 'user_management.roles.destroy', name: 'Delete Role', resource: 'user_management.roles', section: 'User Management' },

  # Audit Logs
  { code: 'audit_logs.index', name: 'View Audit Logs', resource: 'audit_logs', section: 'Audit Logs' },
  { code: 'audit_logs.show', name: 'View Audit Log Details', resource: 'audit_logs', section: 'Audit Logs' }
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

# Superadmin role (all permissions)
superadmin = Role.find_or_create_by!(name: 'Superadmin') do |role|
  role.description = 'Full system access - bypasses all permission checks'
end
# Note: Superadmin bypasses permission checks, but assign all for visibility
superadmin.permissions = Permission.all

# Admin role (all except role management)
admin = Role.find_or_create_by!(name: 'Admin') do |role|
  role.description = 'Administrative access - can manage users and dashboards'
end
admin_permissions = Permission.where.not(code: [
                                            'user_management.roles.create',
                                            'user_management.roles.update',
                                            'user_management.roles.destroy'
                                          ])
admin.permissions = admin_permissions

# Operator role (dashboard management only)
operator = Role.find_or_create_by!(name: 'Operator') do |role|
  role.description = 'Dashboard operator - can manage BI dashboards'
end
operator_permissions = Permission.where(code: [
                                           'dashboard.index',
                                           'bi_dashboards.index',
                                           'bi_dashboards.projects.index',
                                           'bi_dashboards.projects.show',
                                           'bi_dashboards.projects.create',
                                           'bi_dashboards.projects.update'
                                         ])
operator.permissions = operator_permissions

# Viewer role (read-only access)
viewer = Role.find_or_create_by!(name: 'Viewer') do |role|
  role.description = 'Read-only access to dashboards'
end
viewer_permissions = Permission.where(code: [
                                        'dashboard.index',
                                        'bi_dashboards.index'
                                      ])
viewer.permissions = viewer_permissions

puts "✓ Created #{Role.count} roles"

# ============================================================================
# USERS
# ============================================================================
puts "\n👤 Creating users..."
puts '─' * 80

user_configs = [
  {
    email: 'superadmin@example.com',
    name: 'Super Admin',
    password: 'password123',
    password_confirmation: 'password123',
    role: superadmin
  },
  {
    email: 'admin@example.com',
    name: 'Admin User',
    password: 'password123',
    password_confirmation: 'password123',
    role: admin
  },
  {
    email: 'operator@example.com',
    name: 'Operator User',
    password: 'password123',
    password_confirmation: 'password123',
    role: operator
  },
  {
    email: 'viewer@example.com',
    name: 'Viewer User',
    password: 'password123',
    password_confirmation: 'password123',
    role: viewer
  }
]

user_configs.each do |config|
  User.find_or_create_by!(email: config[:email]) do |user|
    user.name = config[:name]
    user.password = config[:password]
    user.password_confirmation = config[:password_confirmation]
    user.role = config[:role]
  end
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
    code: 'SALES_ANALYTICS',
    description: 'Sales performance and revenue analytics dashboards',
    status: 'active',
    dashboards: [
      { name: 'Sales Overview', embed_url: 'https://example.com/embed/sales-overview', embed_type: 'iframe', status: 'active' },
      { name: 'Revenue Breakdown', embed_url: 'https://example.com/embed/revenue', embed_type: 'iframe', status: 'active' }
    ]
  },
  {
    name: 'Marketing Insights',
    code: 'MARKETING_INSIGHTS',
    description: 'Marketing campaign performance dashboards',
    status: 'active',
    dashboards: [
      { name: 'Campaign Performance', embed_url: 'https://example.com/embed/campaigns', embed_type: 'iframe', status: 'active' }
    ]
  },
  {
    name: 'Operations Dashboard',
    code: 'OPERATIONS',
    description: 'Operational metrics and KPIs',
    status: 'inactive',
    dashboards: []
  }
]

project_configs.each do |config|
  project = Project.find_or_create_by!(code: config[:code]) do |p|
    p.name = config[:name]
    p.description = config[:description]
    p.status = config[:status]
  end

  config[:dashboards].each_with_index do |dash_config, index|
    project.dashboards.find_or_create_by!(name: dash_config[:name]) do |d|
      d.embed_url = dash_config[:embed_url]
      d.embed_type = dash_config[:embed_type]
      d.status = dash_config[:status]
      d.position = index
    end
  end
end

puts "✓ Created #{Project.count} projects with #{Dashboard.count} dashboards"

# ============================================================================
# FINALIZATION
# ============================================================================
puts "\n🎉 Seeding completed successfully!"
puts '─' * 80
puts "\nDefault credentials:"
puts '  📧 Email: superadmin@example.com'
puts '  🔑 Password: password123'
puts '  👔 Role: Superadmin (full access)'
puts ''
puts '  📧 Email: admin@example.com'
puts '  🔑 Password: password123'
puts '  👔 Role: Admin'
puts ''
puts '  📧 Email: operator@example.com'
puts '  🔑 Password: password123'
puts '  👔 Role: Operator'
puts ''
puts '  📧 Email: viewer@example.com'
puts '  🔑 Password: password123'
puts '  👔 Role: Viewer (read-only)'
puts '─' * 80
