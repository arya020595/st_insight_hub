class ProjectPolicy < ApplicationPolicy
  # READ: View specific project details
  # Users can only view projects they're assigned to (unless superadmin)
  def show?
    return false unless user.has_permission?(build_permission_code("show"))

    # Superadmin sees all, others only see assigned projects
    user.superadmin? || user_assigned_to_project?
  end

  private

  def permission_resource
    "projects"
  end

  def user_assigned_to_project?
    user.dashboards.where(project: record).exists?
  end

  class Scope < ApplicationPolicy::Scope
    private

    def permission_resource
      "projects"
    end

    def apply_role_based_scope
      # Client users can only see projects they're assigned to
      scope.joins(dashboards: :users)
           .where(users: { id: user.id })
           .distinct
    end
  end
end
