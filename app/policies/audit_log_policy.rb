# frozen_string_literal: true

class AuditLogPolicy < ApplicationPolicy
  def show?
    return true if user.superadmin?
    return false unless user.has_permission?(build_permission_code("show"))

    # Non-superadmin users can only view their own audit logs
    record.user_id == user.id
  end

  private

  def permission_resource
    "audit_logs"
  end

  class Scope < ApplicationPolicy::Scope
    private

    def permission_resource
      "audit_logs"
    end

    # Non-superadmin users can only see their own audit logs
    def apply_role_based_scope
      scope.where(user_id: user.id)
    end
  end
end
