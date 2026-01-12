# frozen_string_literal: true

class BiDashboardPolicy < ApplicationPolicy
  def index?
    user.has_permission?('bi_dashboards.index')
  end

  private

  def permission_resource
    'bi_dashboards'
  end

  class Scope < ApplicationPolicy::Scope
    private

    def permission_resource
      'bi_dashboards'
    end
  end
end
