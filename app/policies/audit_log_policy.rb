# frozen_string_literal: true

class AuditLogPolicy < ApplicationPolicy
  private

  def permission_resource
    'audit_logs'
  end

  class Scope < ApplicationPolicy::Scope
    private

    def permission_resource
      'audit_logs'
    end
  end
end
