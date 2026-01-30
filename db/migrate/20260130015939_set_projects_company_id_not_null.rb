class SetProjectsCompanyIdNotNull < ActiveRecord::Migration[8.1]
  def up
    # Backfill: Ensure all projects have a company_id
    # Option 1: Assign orphaned projects to the first company
    # Option 2: Delete orphaned projects (use with caution)
    # Option 3: Fail the migration if orphaned projects exist (safest for production)

    # Check for projects without company_id
    orphaned_count = Project.where(company_id: nil).count

    if orphaned_count > 0
      # Safest approach: fail and require manual intervention
      raise ActiveRecord::IrreversibleMigration,
            "Cannot set company_id to NOT NULL: #{orphaned_count} project(s) have NULL company_id. " \
            "Please manually assign these projects to a company before running this migration."

      # Alternative: Auto-assign to first company (uncomment if preferred)
      # first_company = Company.kept.first
      # if first_company
      #   say_with_time "Backfilling #{orphaned_count} orphaned projects to company: #{first_company.name}" do
      #     Project.where(company_id: nil).update_all(company_id: first_company.id)
      #   end
      # else
      #   raise ActiveRecord::IrreversibleMigration,
      #         "Cannot set company_id to NOT NULL: No companies exist to assign orphaned projects."
      # end
    end

    # Now safe to add NOT NULL constraint
    safety_assured { change_column_null :projects, :company_id, false }
  end

  def down
    # Allow NULL again (reversible)
    change_column_null :projects, :company_id, true
  end
end
