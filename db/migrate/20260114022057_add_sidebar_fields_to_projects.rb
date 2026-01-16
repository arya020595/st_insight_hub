class AddSidebarFieldsToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :icon, :string, default: "bi-folder"
    add_column :projects, :show_in_sidebar, :boolean, default: true
    add_column :projects, :sidebar_position, :integer, default: 0
  end
end
