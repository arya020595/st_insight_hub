# frozen_string_literal: true

class BiDashboardPolicy < ApplicationPolicy
  def index?
    user.has_permission?("bi_dashboards.index")
  end

  # Check if user can access a specific dashboard
  def show?
    return true if user.superadmin?
    return false unless user.has_permission?(build_permission_code("index"))

    # Non-superadmin users can only access dashboards from their assigned projects
    record.project.users.exists?(user.id)
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

    # Non-superadmin users only see projects assigned to them
    def apply_role_based_scope
      scope.joins(:project_users).where(project_users: { user_id: user.id })
    end
  end
end
