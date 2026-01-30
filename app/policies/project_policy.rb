# frozen_string_literal: true

class ProjectPolicy < ApplicationPolicy
  # Client users can only view projects they're assigned to
  def show?
    return true if user.superadmin?
    return false unless user.has_permission?(build_permission_code("show"))

    user_assigned_to_project?
  end

  def update?
    return true if user.superadmin?
    return false unless user.has_permission?(build_permission_code("update"))

    user_assigned_to_project?
  end

  def destroy?
    return true if user.superadmin?
    return false unless user.has_permission?(build_permission_code("destroy"))

    user_assigned_to_project?
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

    def apply_role_based_scope
      # Client users can only see projects they're assigned to
      scope.joins(:users).where(users: { id: user.id })
    end

    def permission_resource
      "bi_dashboards.projects"
    end
  end
end
