# frozen_string_literal: true

class ProjectsController < ApplicationController
  include Auditable

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
      audit_create(@project, module_name: "projects")
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
    updated = audit_update(@project, module_name: "projects") do
      @project.update(filtered_project_params)
    end

    if updated
      IconFileService.new(@project).handle_icon_change(project_params)
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
    @project.discard
    audit_delete(@project, module_name: "projects")
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

  # Reload projects list for turbo stream responses
  def reload_projects_list
    @q = policy_scope(Project).kept.ransack(params[:q])
    @q.sorts = "created_at desc" if @q.sorts.empty?
    @pagy, @projects = pagy(@q.result.includes(:company))
  end
end
