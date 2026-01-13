# frozen_string_literal: true

module UserManagement
  class UsersController < ApplicationController
    before_action :set_user, only: %i[show edit update destroy restore confirm_delete]

    def index
      authorize User, policy_class: UserManagement::UserPolicy
      @q = policy_scope(User, policy_scope_class: UserManagement::UserPolicy::Scope).kept.ransack(params[:q])
      @q.sorts = "created_at desc" if @q.sorts.empty?
      @pagy, @users = pagy(@q.result.includes(:role))
    end

    def show; end

    def new
      authorize User, policy_class: UserManagement::UserPolicy
      @user = User.new
    end

    def create
      authorize User, policy_class: UserManagement::UserPolicy
      @user = User.new(user_params)

      if @user.save
        log_audit(
          action: "create",
          module_name: "user_management",
          auditable: @user,
          summary: "Created user: #{@user.email}",
          data_after: @user.attributes.except("encrypted_password")
        )
        redirect_to user_management_users_path, notice: "User was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      data_before = @user.attributes.except("encrypted_password").dup

      # Remove password params if blank
      user_update_params = user_params
      if user_update_params[:password].blank?
        user_update_params.delete(:password)
        user_update_params.delete(:password_confirmation)
      end

      if @user.update(user_update_params)
        log_audit(
          action: "update",
          module_name: "user_management",
          auditable: @user,
          summary: "Updated user: #{@user.email}",
          data_before: data_before,
          data_after: @user.attributes.except("encrypted_password")
        )
        redirect_to user_management_users_path, notice: "User was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      data_before = @user.attributes.except("encrypted_password").dup
      @user.discard

      log_audit(
        action: "delete",
        module_name: "user_management",
        auditable: @user,
        summary: "Deleted user: #{@user.email}",
        data_before: data_before
      )
      redirect_to user_management_users_path, notice: "User was successfully deleted."
    end

    def confirm_delete
      authorize @user, :confirm_delete?, policy_class: UserManagement::UserPolicy

      if turbo_frame_request?
        render layout: false
      else
        redirect_to user_management_users_path
      end
    end

    def restore
      @user.undiscard

      log_audit(
        action: "restore",
        module_name: "user_management",
        auditable: @user,
        summary: "Restored user: #{@user.email}"
      )
      redirect_to user_management_users_path, notice: "User was successfully restored."
    end

    private

    def set_user
      @user = User.find(params[:id])
      authorize @user, policy_class: UserManagement::UserPolicy
    end

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :role_id)
    end
  end
end
