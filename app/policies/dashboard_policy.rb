# frozen_string_literal: true

class DashboardPolicy < ApplicationPolicy
  def index?
    user.has_permission?('dashboard.index')
  end

  private

  def permission_resource
    'dashboard'
  end
end
