# frozen_string_literal: true

class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    password_changed = params[:user][:password].present?

    if @user.update_with_password(profile_params_with_password)
      bypass_sign_in(@user) if password_changed # Keep user signed in after password change
      notice_message = password_changed ? "Profile and password updated successfully." : "Profile updated successfully."
      redirect_to profile_path, notice: notice_message
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params_with_password
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :current_password)
  end

  def profile_params_without_password
    params.require(:user).permit(:name, :email)
  end
end
