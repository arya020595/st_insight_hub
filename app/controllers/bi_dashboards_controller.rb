# frozen_string_literal: true

class BiDashboardsController < ApplicationController
  def index
    authorize :bi_dashboard, :index?

    @projects = Project.kept.active.visible_in_sidebar.sidebar_ordered.includes(:dashboards)
  end

  def show
    authorize :bi_dashboard, :index?

    @dashboard = Dashboard.kept.find(params[:id])
    @project = @dashboard.project
  end
end
