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
    @project = Project.new(project_params)

    if @project.save
      log_audit(
        action: "create",
        module_name: "projects",
        auditable: @project,
        summary: "Created project: #{@project.name}",
        data_after: @project.attributes
      )

      # Reload projects list for turbo stream
      @q = policy_scope(Project).kept.ransack(params[:q])
      @q.sorts = "created_at desc" if @q.sorts.empty?
      @pagy, @projects = pagy(@q.result.includes(:company))

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

    if @project.update(project_params)
      log_audit(
        action: "update",
        module_name: "projects",
        auditable: @project,
        summary: "Updated project: #{@project.name}",
        data_before: data_before,
        data_after: @project.attributes
      )

      # Reload projects list for turbo stream
      @q = policy_scope(Project).kept.ransack(params[:q])
      @q.sorts = "created_at desc" if @q.sorts.empty?
      @pagy, @projects = pagy(@q.result.includes(:company))

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

    log_audit(
      action: "delete",
      module_name: "projects",
      auditable: @project,
      summary: "Deleted project: #{@project.name}",
      data_before: data_before
    )

    # Reload projects list for turbo stream
    @q = policy_scope(Project).kept.ransack(params[:q])
    @q.sorts = "created_at desc" if @q.sorts.empty?
    @pagy, @projects = pagy(@q.result.includes(:company))

    respond_to do |format|
      format.html { redirect_to projects_path, notice: "Project was successfully deleted." }
      format.turbo_stream
    end
  end

  def confirm_delete; end

  # AJAX endpoint to get users for a specific company
  def company_users
    company = Company.find(params[:company_id])
    users = company.users.kept
                   .joins(:role)
                   .where.not(roles: { name: "Superadmin" })
                   .order(:name)
                   .pluck(:id, :name, :email)

    render json: users.map { |id, name, email| { id: id, name: name, email: email } }
  end

  private

  def set_project
    @project = Project.kept.includes(:company, :users).find(params[:id])
    authorize @project
  end

  def project_params
    permitted = [ :name, :code, :description, :status, :icon, :show_in_sidebar, :sidebar_position, :company_id, user_ids: [] ]
    params.require(:project).permit(permitted)
  end
end
