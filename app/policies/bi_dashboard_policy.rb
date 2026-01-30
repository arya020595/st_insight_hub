# frozen_string_literal: true

class BiDashboardPolicy < ApplicationPolicy
  # Inherit index? from ApplicationPolicy
  # Automatically checks superadmin and permissions

  # Check if user can access a specific dashboard
  def show?
    return true if user.superadmin?
    return false unless user.has_permission?(build_permission_code("index"))

    # Client users can only access dashboards from projects they're assigned to
    user.project_ids.include?(record.project_id)
  end

  private

  def permission_resource
    "bi_dashboards"
  end

  class Scope < ApplicationPolicy::Scope
    private

    def permission_resource
      "bi_dashboards"
    end

    # Client users only see projects they're assigned to or dashboards from those projects
    def apply_role_based_scope
      case scope.model_name.name
      when "Project"
        # Filter projects by user assignment
        scope.joins(:users).where(users: { id: user.id })
      when "Dashboard"
        # Filter dashboards by project assignment
        scope.joins(:project).merge(Project.joins(:users).where(users: { id: user.id }))
      else
        # Fallback: return empty relation for unsupported models
        scope.none
      end
    end
  end
end
