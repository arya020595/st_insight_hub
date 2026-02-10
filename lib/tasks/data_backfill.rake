# frozen_string_literal: true

namespace :data do
  desc "Backfill company_id for projects that don't have one"
  task backfill_project_companies: :environment do
    orphaned_projects = Project.where(company_id: nil)
    count = orphaned_projects.count

    if count.zero?
      puts "✓ All projects have a company_id. No backfill needed."
      next
    end

    puts "Found #{count} project(s) without company_id."
    puts "\nOptions:"
    puts "1. Assign all orphaned projects to a specific company"
    puts "2. Delete all orphaned projects (DESTRUCTIVE)"
    puts "3. Cancel"

    print "\nChoose an option (1-3): "
    choice = $stdin.gets.chomp

    case choice
    when "1"
      companies = Company.kept.order(:name)
      if companies.empty?
        puts "✗ No companies exist. Please create a company first."
        next
      end

      puts "\nAvailable companies:"
      companies.each_with_index do |company, index|
        puts "#{index + 1}. #{company.name}"
      end

      print "\nSelect company number (1-#{companies.count}): "
      company_choice = $stdin.gets.chomp.to_i

      if company_choice < 1 || company_choice > companies.count
        puts "✗ Invalid selection."
        next
      end

      selected_company = companies[company_choice - 1]

      print "\nAssign #{count} project(s) to '#{selected_company.name}'? (yes/no): "
      confirmation = $stdin.gets.chomp.downcase

      if confirmation == "yes"
        orphaned_projects.update_all(company_id: selected_company.id)
        puts "✓ Successfully assigned #{count} project(s) to '#{selected_company.name}'."
      else
        puts "Cancelled."
      end

    when "2"
      print "\n⚠️  WARNING: This will permanently delete #{count} project(s). Type 'DELETE' to confirm: "
      confirmation = $stdin.gets.chomp

      if confirmation == "DELETE"
        orphaned_projects.destroy_all
        puts "✓ Deleted #{count} project(s)."
      else
        puts "Cancelled."
      end

    when "3"
      puts "Cancelled."

    else
      puts "✗ Invalid choice."
    end
  end

  desc "Check data integrity for company relationships"
  task check_company_integrity: :environment do
    puts "Checking data integrity..."
    puts ""

    # Check projects without company
    orphaned_projects = Project.where(company_id: nil).count
    if orphaned_projects > 0
      puts "✗ Found #{orphaned_projects} project(s) without company_id"
    else
      puts "✓ All projects have company_id"
    end

    # Check users without company (excluding superadmins)
    orphaned_users = User.kept
                         .joins(:role)
                         .where.not(roles: { name: "Superadmin" })
                         .where(company_id: nil)
                         .count
    if orphaned_users > 0
      puts "✗ Found #{orphaned_users} non-superadmin user(s) without company_id"
    else
      puts "✓ All non-superadmin users have company_id"
    end

    # Check for projects belonging to non-existent companies
    invalid_company_refs = Project.where.not(company_id: Company.select(:id)).count
    if invalid_company_refs > 0
      puts "✗ Found #{invalid_company_refs} project(s) with invalid company_id"
    else
      puts "✓ All project company references are valid"
    end

    puts ""
    puts "Data integrity check complete."
  end
end
