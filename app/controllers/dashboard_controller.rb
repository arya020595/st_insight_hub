# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    authorize :dashboard, :index?

    @projects_count = Project.kept.count
    @dashboards_count = Dashboard.kept.count
    @users_count = User.kept.count
    @audit_logs_count = AuditLog.count
    @recent_logs = AuditLog.recent.limit(10)
  end
end
