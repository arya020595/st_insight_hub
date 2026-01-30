# frozen_string_literal: true

class CompaniesController < ApplicationController
  before_action :set_company, only: %i[show edit update destroy restore confirm_delete assign_users update_users remove_user]

  def index
    authorize Company
    @q = policy_scope(Company).kept.ransack(params[:q])
    @q.sorts = "created_at desc" if @q.sorts.empty?
    @pagy, @companies = pagy(@q.result)
  end

  def show
    @users = @company.users.kept.includes(:role).order(:name)
  end

  def new
    authorize Company
    @company = Company.new
  end

  def create
    authorize Company
    @company = Company.new(company_params)

    if @company.save
      log_audit(
        action: "create",
        module_name: "company_management",
        auditable: @company,
        summary: "Created company: #{@company.name}",
        data_after: @company.attributes
      )
      redirect_to companies_path, notice: "Company was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    data_before = @company.attributes.dup

    if @company.update(company_params)
      log_audit(
        action: "update",
        module_name: "company_management",
        auditable: @company,
        summary: "Updated company: #{@company.name}",
        data_before: data_before,
        data_after: @company.attributes
      )
      redirect_to companies_path, notice: "Company was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    data_before = @company.attributes.dup

    if @company.projects.kept.any?
      redirect_to companies_path, alert: "Cannot delete company with active projects."
      return
    end

    @company.discard

    log_audit(
      action: "delete",
      module_name: "company_management",
      auditable: @company,
      summary: "Deleted company: #{@company.name}",
      data_before: data_before
    )
    redirect_to companies_path, notice: "Company was successfully deleted."
  end

  def confirm_delete
    authorize @company, :confirm_delete?

    if turbo_frame_request?
      render layout: false
    else
      redirect_to companies_path
    end
  end

  def restore
    @company.undiscard

    log_audit(
      action: "restore",
      module_name: "company_management",
      auditable: @company,
      summary: "Restored company: #{@company.name}"
    )
    redirect_to companies_path, notice: "Company was successfully restored."
  end

  def assign_users
    @assigned_users = @company.users.kept.order(:name)
    @available_users = User.kept.where.not(id: @company.user_ids).order(:name)
  end

  def update_users
    user_ids = params[:company][:user_ids].reject(&:blank?)

    if @company.update(user_ids: user_ids)
      log_audit(
        action: "update",
        module_name: "company_management",
        auditable: @company,
        summary: "Updated user assignments for company: #{@company.name}"
      )
      @users = @company.users.kept.includes(:role).order(:name)
      flash.now[:notice] = "Users assigned successfully."
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to company_path(@company), notice: "Users assigned successfully." }
      end
    else
      @assigned_users = @company.users.kept.order(:name)
      @available_users = User.kept.where.not(id: @company.user_ids).order(:name)
      render :assign_users, status: :unprocessable_entity
    end
  end

  def remove_user
    user = User.find(params[:user_id])

    if @company.users.delete(user)
      log_audit(
        action: "update",
        module_name: "company_management",
        auditable: @company,
        summary: "Removed user #{user.name} from company: #{@company.name}"
      )
      @users = @company.users.kept.includes(:role).order(:name)
      flash.now[:notice] = "User was successfully removed from the company."
      respond_to do |format|
        format.turbo_stream { render :update_users }
        format.html { redirect_to company_path(@company), notice: "User was successfully removed from the company." }
      end
    else
      flash.now[:alert] = "Failed to remove user from the company."
      respond_to do |format|
        format.turbo_stream { render :update_users }
        format.html { redirect_to company_path(@company), alert: "Failed to remove user from the company." }
      end
    end
  end

  private

  def set_company
    @company = Company.find(params[:id])
    authorize @company
  end

  def company_params
    params.require(:company).permit(:name, :code, :status, :description)
  end
end
