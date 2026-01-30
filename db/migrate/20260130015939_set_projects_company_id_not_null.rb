class SetProjectsCompanyIdNotNull < ActiveRecord::Migration[8.1]
  def change
    safety_assured { change_column_null :projects, :company_id, false }
  end
end
