# frozen_string_literal: true

class BiDashboardsController < ApplicationController
  def index
    authorize :bi_dashboard, :index?

    @projects = policy_scope(Project, policy_scope_class: BiDashboardPolicy::Scope)
                  .kept.active.visible_in_sidebar.sidebar_ordered
                  .includes(:dashboards)
  end

  def show
    @dashboard = Dashboard.kept.find(params[:id])
    @project = @dashboard.project

    # Eager load owner for superadmin display
    @project = Project.includes(:created_by).find(@project.id) if current_user.superadmin?

    # Check project is active and visible in sidebar
    raise ActiveRecord::RecordNotFound unless @project.active? && @project.show_in_sidebar?

    # Use policy to check if user can access this dashboard
    authorize @dashboard, :show?, policy_class: BiDashboardPolicy
  end
end
