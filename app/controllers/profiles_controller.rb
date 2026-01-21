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

    # Check if user is trying to update password
    if params[:user][:password].present?
      # Devise requires current password for security when updating password
      if @user.update_with_password(profile_params_with_password)
        bypass_sign_in(@user) # Keep user signed in after password change
        redirect_to profile_path, notice: "Profile and password updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    else
      # Update without password
      if @user.update_without_password(profile_params_without_password)
        redirect_to profile_path, notice: "Profile updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
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
