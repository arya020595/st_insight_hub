# frozen_string_literal: true

class BiDashboardsController < ApplicationController
  def index
    authorize :bi_dashboard, :index?

    @projects = Project.kept.active.includes(:dashboards)
    @selected_project = if params[:project_id].present?
                          Project.kept.find_by(id: params[:project_id])
    else
                          @projects.first
    end

    @dashboards = @selected_project&.dashboards&.kept&.active&.ordered || []
    @selected_dashboard = if params[:dashboard_id].present?
                            @dashboards.find_by(id: params[:dashboard_id])
    else
                            @dashboards.first
    end
  end
end
