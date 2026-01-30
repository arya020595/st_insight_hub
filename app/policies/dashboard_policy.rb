# frozen_string_literal: true

class DashboardPolicy < ApplicationPolicy
  # Inherit index? from ApplicationPolicy
  # Automatically checks superadmin and permission_resource

  private

  def permission_resource
    "dashboard"
  end
end
