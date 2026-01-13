# frozen_string_literal: true

module UserManagement
  class RolesController < ApplicationController
    before_action :set_role, only: %i[show edit update destroy confirm_delete]

    def index
      authorize Role, policy_class: UserManagement::RolePolicy
      @q = policy_scope(Role, policy_scope_class: UserManagement::RolePolicy::Scope).kept.ransack(params[:q])
      @q.sorts = "name asc" if @q.sorts.empty?
      @pagy, @roles = pagy(@q.result.includes(:permissions))
    end

    def show
      @permissions_by_section = @role.permissions.group_by(&:section)
    end

    def new
      authorize Role, policy_class: UserManagement::RolePolicy
      @role = Role.new
      @permissions = Permission.kept.order(:section, :name)
    end

    def create
      authorize Role, policy_class: UserManagement::RolePolicy
      @role = Role.new(role_params)

      if @role.save
        update_permissions
        log_audit(
          action: "create",
          module_name: "user_management",
          auditable: @role,
          summary: "Created role: #{@role.name}",
          data_after: @role.attributes.merge(permission_ids: @role.permission_ids)
        )
        redirect_to user_management_roles_path, notice: "Role was successfully created."
      else
        @permissions = Permission.kept.order(:section, :name)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @permissions = Permission.kept.order(:section, :name)
    end

    def update
      data_before = @role.attributes.merge(permission_ids: @role.permission_ids).dup

      if @role.update(role_params)
        update_permissions
        log_audit(
          action: "update",
          module_name: "user_management",
          auditable: @role,
          summary: "Updated role: #{@role.name}",
          data_before: data_before,
          data_after: @role.attributes.merge(permission_ids: @role.permission_ids)
        )
        redirect_to user_management_roles_path, notice: "Role was successfully updated."
      else
        @permissions = Permission.kept.order(:section, :name)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      data_before = @role.attributes.dup
      @role.discard

      log_audit(
        action: "delete",
        module_name: "user_management",
        auditable: @role,
        summary: "Deleted role: #{@role.name}",
        data_before: data_before
      )
      redirect_to user_management_roles_path, notice: "Role was successfully deleted."
    end

    def confirm_delete
      authorize @role, :confirm_delete?, policy_class: UserManagement::RolePolicy

      if turbo_frame_request?
        render layout: false
      else
        redirect_to user_management_roles_path
      end
    end

    private

    def set_role
      @role = Role.kept.find(params[:id])
      authorize @role, policy_class: UserManagement::RolePolicy
    end

    def role_params
      params.require(:role).permit(:name, :description)
    end

    def update_permissions
      permission_ids = params[:role][:permission_ids]&.reject(&:blank?)&.map(&:to_i) || []
      @role.permission_ids = permission_ids
    end
  end
end
