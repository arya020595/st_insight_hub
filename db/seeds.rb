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

  # Company Management
  { code: 'company_management.companies.index', name: 'View Companies', resource: 'company_management.companies', section: 'Company Management' },
  { code: 'company_management.companies.show', name: 'View Company Details', resource: 'company_management.companies', section: 'Company Management' },
  { code: 'company_management.companies.create', name: 'Create Company', resource: 'company_management.companies', section: 'Company Management' },
  { code: 'company_management.companies.update', name: 'Update Company', resource: 'company_management.companies', section: 'Company Management' },
  { code: 'company_management.companies.destroy', name: 'Delete Company', resource: 'company_management.companies', section: 'Company Management' },

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

# Client role - Client users (read-only access to assigned projects)
client = Role.find_or_create_by!(name: 'Client') do |role|
  role.description = 'Client company users - read-only access to assigned projects and dashboards'
end
client_permissions = Permission.where(code: [
                                       'dashboard.index',
                                       'bi_dashboards.index',
                                       'bi_dashboards.projects.index',
                                       'bi_dashboards.projects.show'
                                     ])
client.permissions = client_permissions

puts "✓ Created #{Role.count} roles"

# ============================================================================
# COMPANIES
# ============================================================================
puts "\n🏢 Creating companies..."
puts '─' * 80

company_a = Company.find_or_create_by!(code: 'COMP_A') do |company|
  company.name = 'Acme Corporation'
  company.description = 'Global technology solutions provider'
  company.status = 'active'
end

company_b = Company.find_or_create_by!(code: 'COMP_B') do |company|
  company.name = 'TechVision Inc'
  company.description = 'Innovative software development company'
  company.status = 'active'
end

company_c = Company.find_or_create_by!(code: 'COMP_C') do |company|
  company.name = 'DataFlow Solutions'
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
    code: 'SALES_ANALYTICS',
    description: 'Sales performance and revenue analytics dashboards',
    icon: 'bi-graph-up',
    status: 'active',
    company: company_a,
    users: [ client_a1, client_a2 ],
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
    company: company_a,
    users: [ client_a1, client_a3 ],
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
    company: company_b,
    users: [ client_b1, client_b2 ],
    dashboards: [
      { name: 'KPI Dashboard', embed_url: 'https://example.com/embed/kpi', embed_type: 'iframe', status: 'active' },
      { name: 'Productivity Metrics', embed_url: 'https://example.com/embed/productivity', embed_type: 'iframe', status: 'active' }
    ]
  },
  {
    name: 'Customer Insights',
    code: 'CUSTOMER_INSIGHTS',
    description: 'Customer behavior and satisfaction analytics',
    icon: 'bi-people',
    status: 'active',
    company: company_c,
    users: [ client_c1, client_c2, client_c3 ],
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
    company: company_c,
    users: [ client_c1, client_c2 ],
    dashboards: [
      { name: 'Budget Overview', embed_url: 'https://example.com/embed/budget', embed_type: 'iframe', status: 'active' },
      { name: 'Expense Tracking', embed_url: 'https://example.com/embed/expenses', embed_type: 'iframe', status: 'active' }
    ]
  }
]

project_configs.each do |config|
  project = Project.find_or_create_by!(code: config[:code], company_id: config[:company].id) do |p|
    p.name = config[:name]
    p.description = config[:description]
    p.icon = config[:icon]
    p.status = config[:status]
  end

  # Assign users to project
  project.users = config[:users]

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
puts "\n🔗 Project Assignments:"

Project.includes(:company, :users).each do |project|
  company_name = project.company&.name || 'No company'
  user_names = project.users.pluck(:name).join(', ')
  puts "   - #{project.name} (#{company_name}): #{user_names}"
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
