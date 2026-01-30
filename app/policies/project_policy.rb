# frozen_string_literal: true

# ============================================================================
# PROJECT POLICY - Based on Business Rules:
#
# 1. Superadmin: Full access to all projects (create, read, update, delete)
# 2. Client: READ-ONLY access to assigned projects only
#    - Can view projects they're assigned to
#    - Cannot create, update, or delete projects
#    - Projects they're not assigned to are completely hidden
#
# Authorization flow:
# - Superadmin bypasses all checks
# - Client must have permission AND be assigned to the project
# ============================================================================

class ProjectPolicy < ApplicationPolicy
  # LIST: View projects list (Dashboard Management)
  # Client users see only their assigned projects (via Scope)
  # Inherits superadmin check from ApplicationPolicy

  # READ: View specific project details
  # Client users can only view projects they're assigned to
  def show?
    return false unless user.has_permission?(build_permission_code("show"))

    # Client users can only view projects they're assigned to
    # Superadmin already has permission and sees all
    user.superadmin? || user_assigned_to_project?
  end

  # CREATE: Only Superadmin can create projects
  # Clients cannot create projects
  def new?
    user.superadmin?
  end

  def create?
    user.superadmin?
  end

  # UPDATE: Only Superadmin can update projects
  # Clients are READ-ONLY
  def edit?
    user.superadmin?
  end

  def update?
    user.superadmin?
  end

  # DELETE: Only Superadmin can delete projects
  # Clients are READ-ONLY
  def confirm_delete?
    user.superadmin?
  end

  def destroy?
    user.superadmin?
  end

  def self.permission_resource
    "bi_dashboards.projects"
  end

  private

  def user_assigned_to_project?
    user.project_ids.include?(record.id)
  end

  class Scope < ApplicationPolicy::Scope
    def apply_role_based_scope
      # Client users can only see projects they're assigned to
      scope.joins(:users).where(users: { id: user.id })
    end
  end
end
