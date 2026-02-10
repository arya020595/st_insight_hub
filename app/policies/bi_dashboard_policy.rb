# frozen_string_literal: true

class BiDashboardPolicy < ApplicationPolicy
  # Inherit index? from ApplicationPolicy
  # Automatically checks superadmin and permissions

  # Check if user can access a specific dashboard
  def show?
    return false unless user.has_permission?(build_permission_code("show"))

    # Superadmin sees all, others only see dashboards they're assigned to
    user.superadmin? || user.dashboard_ids.include?(record.id)
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

    # Client users only see dashboards they're assigned to
    def apply_role_based_scope
      case scope.model_name.name
      when "Project"
        # Filter projects that have dashboards assigned to the user
        scope.joins(dashboards: :users).where(dashboards_users: { user_id: user.id }).distinct
      when "Dashboard"
        # Filter dashboards by user assignment
        scope.joins(:users).where(dashboards_users: { user_id: user.id })
      else
        # Fallback: return empty relation for unsupported models
        scope.none
      end
    end
  end
end
