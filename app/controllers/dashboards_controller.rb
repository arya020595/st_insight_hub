# frozen_string_literal: true

class DashboardsController < ApplicationController
  before_action :set_project
  before_action :set_dashboard, only: %i[edit update destroy confirm_delete]

  def new
    authorize @project, :update?
    @dashboard = @project.dashboards.build
  end

  def create
    authorize @project, :update?
    @dashboard = @project.dashboards.build(dashboard_params)

    if @dashboard.save
      log_audit(
        action: "create",
        module_name: "dashboards",
        auditable: @dashboard,
        summary: "Created dashboard: #{@dashboard.name} in project: #{@project.name}",
        data_after: @dashboard.attributes
      )
      @dashboards = @project.dashboards.kept.ordered
      flash.now[:notice] = "Dashboard was successfully created."
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @project, notice: "Dashboard was successfully created." }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @project, :update?
  end

  def update
    authorize @project, :update?
    data_before = @dashboard.attributes.dup

    if @dashboard.update(dashboard_params)
      log_audit(
        action: "update",
        module_name: "dashboards",
        auditable: @dashboard,
        summary: "Updated dashboard: #{@dashboard.name}",
        data_before: data_before,
        data_after: @dashboard.attributes
      )
      @dashboards = @project.dashboards.kept.ordered
      flash.now[:notice] = "Dashboard was successfully updated."
      respond_to do |format|
        format.turbo_stream { render :create }
        format.html { redirect_to @project, notice: "Dashboard was successfully updated." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @project, :destroy?
    data_before = @dashboard.attributes.dup
    @dashboard.discard

    log_audit(
      action: "delete",
      module_name: "dashboards",
      auditable: @dashboard,
      summary: "Deleted dashboard: #{@dashboard.name}",
      data_before: data_before
    )

    @dashboards = @project.dashboards.kept.ordered
    flash.now[:notice] = "Dashboard was successfully deleted."
    respond_to do |format|
      format.turbo_stream { render :create }
      format.html { redirect_to @project, notice: "Dashboard was successfully deleted." }
    end
  end

  def confirm_delete
    authorize @project, :destroy?
  end

  private

  def set_project
    @project = Project.kept.find(params[:project_id])
  end

  def set_dashboard
    @dashboard = @project.dashboards.kept.find(params[:id])
  end

  def dashboard_params
    params.require(:dashboard).permit(:name, :embed_url, :embed_type, :status, :position, user_ids: [])
  end
end
