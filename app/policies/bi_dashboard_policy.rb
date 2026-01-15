# frozen_string_literal: true

class BiDashboardPolicy < ApplicationPolicy
  def index?
    user.has_permission?("bi_dashboards.index")
  end

  # Check if user can access a specific dashboard
  def show?
    return true if user.superadmin?
    return false unless user.has_permission?(build_permission_code("index"))

    # Non-superadmin users can only access dashboards from projects they own
    record.project.created_by_id == user.id
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

    # Non-superadmin users only see projects they own or dashboards from projects they own
    def apply_role_based_scope
      case scope.model_name.name
      when "Project"
        # Filter projects by owner
        scope.where(created_by_id: user.id)
      when "Dashboard"
        # Filter dashboards by project owner
        scope.joins(:project).where(projects: { created_by_id: user.id })
      else
        # Fallback: return empty relation for unsupported models
        scope.none
      end
    end
  end
end
