# frozen_string_literal: true

class ProjectPolicy < ApplicationPolicy
  # Admin can only show/edit/destroy their own projects
  def show?
    return true if user.superadmin?
    return false unless user.has_permission?(build_permission_code("show"))

    user_owns_project?
  end

  def update?
    return true if user.superadmin?
    return false unless user.has_permission?(build_permission_code("update"))

    user_owns_project?
  end

  def destroy?
    return true if user.superadmin?
    return false unless user.has_permission?(build_permission_code("destroy"))

    user_owns_project?
  end

  private

  def permission_resource
    "bi_dashboards.projects"
  end

  def user_owns_project?
    record.created_by_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    private

    def apply_role_based_scope
      # Admin can only see projects they own (created_by)
      scope.where(created_by_id: user.id)
    end

    def permission_resource
      "bi_dashboards.projects"
    end
  end
end
