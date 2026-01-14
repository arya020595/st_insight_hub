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

# Superadmin role (all permissions) - Development team
superadmin = Role.find_or_create_by!(name: 'Superadmin') do |role|
  role.description = 'Full system access - bypasses all permission checks. For development team only.'
end
# Note: Superadmin bypasses permission checks, but assign all for visibility
superadmin.permissions = Permission.all

# Admin role - Client users (each admin represents a company)
admin = Role.find_or_create_by!(name: 'Admin') do |role|
  role.description = 'Client company access - can only see assigned projects and dashboards'
end
admin_permissions = Permission.where(code: [
                                       'dashboard.index',
                                       'bi_dashboards.index',
                                       'bi_dashboards.projects.index',
                                       'bi_dashboards.projects.show',
                                       'bi_dashboards.projects.create',
                                       'bi_dashboards.projects.update',
                                       'bi_dashboards.projects.destroy'
                                     ])
admin.permissions = admin_permissions

puts "✓ Created #{Role.count} roles"

# ============================================================================
# USERS
# ============================================================================
puts "\n👤 Creating users..."
puts '─' * 80

# Superadmin - Development team
superadmin_user = User.find_or_create_by!(email: 'superadmin@example.com') do |user|
  user.name = 'Super Admin'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = superadmin
end

# Admin users - Each represents a company/client
admin_company_a = User.find_or_create_by!(email: 'admin.company.a@example.com') do |user|
  user.name = 'Company A Admin'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = admin
end

admin_company_b = User.find_or_create_by!(email: 'admin.company.b@example.com') do |user|
  user.name = 'Company B Admin'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = admin
end

admin_company_c = User.find_or_create_by!(email: 'admin.company.c@example.com') do |user|
  user.name = 'Company C Admin'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = admin
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
    icon: 'bi-graph-up',
    status: 'active',
    assigned_users: [ admin_company_a ],
    dashboards: [
      { name: 'Sales Overview', embed_url: 'https://example.com/embed/sales-overview', embed_type: 'iframe', status: 'active' },
      { name: 'Revenue Breakdown', embed_url: 'https://example.com/embed/revenue', embed_type: 'iframe', status: 'active' }
    ]
  },
  {
    name: 'Marketing Insights',
    code: 'MARKETING_INSIGHTS',
    description: 'Marketing campaign performance dashboards',
    icon: 'bi-megaphone',
    status: 'active',
    assigned_users: [ admin_company_a, admin_company_b ],
    dashboards: [
      { name: 'Campaign Performance', embed_url: 'https://example.com/embed/campaigns', embed_type: 'iframe', status: 'active' },
      { name: 'Social Media Analytics', embed_url: 'https://example.com/embed/social', embed_type: 'iframe', status: 'active' }
    ]
  },
  {
    name: 'Operations Dashboard',
    code: 'OPERATIONS',
    description: 'Operational metrics and KPIs',
    icon: 'bi-gear',
    status: 'active',
    assigned_users: [ admin_company_b ],
    dashboards: [
      { name: 'KPI Dashboard', embed_url: 'https://example.com/embed/kpi', embed_type: 'iframe', status: 'active' }
    ]
  },
  {
    name: 'Customer Insights',
    code: 'CUSTOMER_INSIGHTS',
    description: 'Customer behavior and satisfaction analytics',
    icon: 'bi-people',
    status: 'active',
    assigned_users: [ admin_company_c ],
    dashboards: [
      { name: 'Customer Satisfaction', embed_url: 'https://example.com/embed/csat', embed_type: 'iframe', status: 'active' },
      { name: 'Churn Analysis', embed_url: 'https://example.com/embed/churn', embed_type: 'iframe', status: 'active' }
    ]
  },
  {
    name: 'Financial Reports',
    code: 'FINANCIAL_REPORTS',
    description: 'Financial performance and budget tracking',
    icon: 'bi-currency-dollar',
    status: 'active',
    assigned_users: [ admin_company_c ],
    dashboards: [
      { name: 'Budget Overview', embed_url: 'https://example.com/embed/budget', embed_type: 'iframe', status: 'active' }
    ]
  }
]

project_configs.each do |config|
  project = Project.find_or_create_by!(code: config[:code]) do |p|
    p.name = config[:name]
    p.description = config[:description]
    p.icon = config[:icon]
    p.status = config[:status]
  end

  # Assign users to project
  config[:assigned_users].each do |user|
    ProjectUser.find_or_create_by!(project: project, user: user)
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
puts "✓ Created #{ProjectUser.count} project-user assignments"

# ============================================================================
# FINALIZATION
# ============================================================================
puts "\n🎉 Seeding completed successfully!"
puts '─' * 80
puts "\n📋 Summary:"
puts '─' * 80
puts "\n👔 Roles: #{Role.count}"
puts "   - Superadmin: Full system access (development team)"
puts "   - Admin: Client company access (scoped to assigned projects)"
puts "\n👤 Users: #{User.count}"
puts "   - 1 Superadmin"
puts "   - #{User.joins(:role).where(roles: { name: 'Admin' }).count} Admin users (representing companies)"
puts "\n📊 Projects: #{Project.count} with #{Dashboard.count} dashboards"
puts "\n🔗 Project Assignments:"

Project.includes(:users).each do |project|
  assigned = project.users.pluck(:name).join(', ')
  assigned = 'None' if assigned.blank?
  puts "   - #{project.name}: #{assigned}"
end

puts "\n" + '─' * 80
puts "\n🔐 Default credentials:"
puts '─' * 80
puts "\n  SUPERADMIN (Development Team - Full Access):"
puts '  📧 Email: superadmin@example.com'
puts '  🔑 Password: password123'
puts ''
puts '  ADMIN - COMPANY A (Sales Analytics, Marketing Insights):'
puts '  📧 Email: admin.company.a@example.com'
puts '  🔑 Password: password123'
puts ''
puts '  ADMIN - COMPANY B (Marketing Insights, Operations Dashboard):'
puts '  📧 Email: admin.company.b@example.com'
puts '  🔑 Password: password123'
puts ''
puts '  ADMIN - COMPANY C (Customer Insights, Financial Reports):'
puts '  📧 Email: admin.company.c@example.com'
puts '  🔑 Password: password123'
puts '─' * 80
