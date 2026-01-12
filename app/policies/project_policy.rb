# frozen_string_literal: true

class ProjectPolicy < ApplicationPolicy
  private

  def permission_resource
    "bi_dashboards.projects"
  end

  class Scope < ApplicationPolicy::Scope
    private

    def permission_resource
      "bi_dashboards.projects"
    end
  end
end
