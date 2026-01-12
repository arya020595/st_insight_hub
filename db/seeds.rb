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
# USERS
# ============================================================================
puts "\n👤 Creating users..."
puts '─' * 80

# Define user configurations
user_configs = [
  {
    email: 'admin@example.com',
    password: 'password123',
    password_confirmation: 'password123'
  },
  {
    email: 'user@example.com',
    password: 'password123',
    password_confirmation: 'password123'
  }
]

# Create users efficiently
user_configs.each do |config|
  User.find_or_create_by!(email: config[:email]) do |user|
    user.password = config[:password]
    user.password_confirmation = config[:password_confirmation]
  end
end

puts "✓ Created #{User.count} users"

# ============================================================================
# FINALIZATION
# ============================================================================
puts "\n🎉 Seeding completed successfully!"
puts '─' * 80
puts "\nDefault credentials:"
puts "  📧 Email: admin@example.com"
puts "  🔑 Password: password123"
puts ''
puts "  📧 Email: user@example.com"
puts "  🔑 Password: password123"
puts '─' * 80
