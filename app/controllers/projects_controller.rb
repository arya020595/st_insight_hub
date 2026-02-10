# frozen_string_literal: true

class ProjectsController < ApplicationController
  before_action :set_project, only: %i[show edit update destroy confirm_delete]

  def index
    authorize Project
    @q = policy_scope(Project).kept.ransack(params[:q])
    @q.sorts = "created_at desc" if @q.sorts.empty?
    @pagy, @projects = pagy(@q.result.includes(:company))
  end

  def show
    @dashboards = @project.dashboards.kept.ordered
  end

  def new
    authorize Project
    @project = Project.new
  end

  def create
    authorize Project
    @project = Project.new(filtered_project_params)

    if @project.save
      log_project_audit("create", "Created project: #{@project.name}", data_after: @project.attributes)
      reload_projects_list

      respond_to do |format|
        format.html { redirect_to projects_path, notice: "Project was successfully created." }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    data_before = @project.attributes.dup

    handle_icon_type_change

    if @project.update(filtered_project_params)
      log_project_audit("update", "Updated project: #{@project.name}", data_before: data_before, data_after: @project.attributes)
      reload_projects_list

      respond_to do |format|
        format.html { redirect_to projects_path, notice: "Project was successfully updated." }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    data_before = @project.attributes.dup
    @project.discard

    log_project_audit("delete", "Deleted project: #{@project.name}", data_before: data_before)
    reload_projects_list

    respond_to do |format|
      format.html { redirect_to projects_path, notice: "Project was successfully deleted." }
      format.turbo_stream
    end
  end

  def confirm_delete; end

  private

  def set_project
    @project = Project.kept.includes(:company).find(params[:id])
    authorize @project
  end

  def project_params
    params.require(:project).permit(
      :name, :description, :status, :icon, :show_in_sidebar,
      :sidebar_position, :company_id, :icon_file, :remove_icon_file, :icon_type
    )
  end

  # Filter out virtual attributes before passing to model
  def filtered_project_params
    project_params.except(:icon_type, :remove_icon_file)
  end

  # Handle icon type switching - purge SVG when switching to Bootstrap
  def handle_icon_type_change
    if switching_to_bootstrap_icon?
      @project.icon_file.purge
    elsif removing_icon_file?
      @project.icon_file.purge
    end
  end

  def switching_to_bootstrap_icon?
    params.dig(:project, :icon_type) == "bootstrap" && @project.icon_file.attached?
  end

  def removing_icon_file?
    params.dig(:project, :remove_icon_file) == "1"
  end

  # Reload projects list for turbo stream responses
  def reload_projects_list
    @q = policy_scope(Project).kept.ransack(params[:q])
    @q.sorts = "created_at desc" if @q.sorts.empty?
    @pagy, @projects = pagy(@q.result.includes(:company))
  end

  # Audit logging helper for project actions
  def log_project_audit(action, summary, data_before: nil, data_after: nil)
    log_audit(
      action: action,
      module_name: "projects",
      auditable: @project,
      summary: summary,
      data_before: data_before,
      data_after: data_after
    )
  end
end
