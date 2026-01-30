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
    "bi_dashboards.projects"
  end

  def user_assigned_to_project?
    user.project_ids.include?(record.id)
  end

  class Scope < ApplicationPolicy::Scope
    private

    def permission_resource
      "bi_dashboards.projects"
    end

    def apply_role_based_scope
      # Client users can only see projects they're assigned to
      scope.joins(:users).where(users: { id: user.id })
    end
  end
end
