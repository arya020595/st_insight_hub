# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate_user!
  before_action :set_current_user

  # Smart layout switching: dashboard for authenticated pages, application for public pages
  layout :set_layout

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def set_layout
    # Use clean layout for Devise controllers (login, signup, password reset)
    # Use dashboard layout for all other authenticated pages
    devise_controller? ? "application" : "dashboard/application"
  end

  def set_current_user
    Current.user = current_user
  end

  # Override Devise method to redirect users to their first accessible resource
  def after_sign_in_path_for(resource)
    stored_location = stored_location_for(resource)
    stored_location || send(resource.first_accessible_path)
  end

  # Override Devise method to redirect after sign out
  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."

    redirect_path = if request.referrer.present? && request.referrer != request.url
                      request.referrer
    else
                      send(current_user.first_accessible_path)
    end

    redirect_to redirect_path, allow_other_host: true
  end

  # Helper to log audit events
  def log_audit(action:, module_name:, auditable: nil, summary: nil, data_before: nil, data_after: nil)
    AuditLog.log(
      action: action,
      module_name: module_name,
      user: current_user,
      auditable: auditable,
      summary: summary,
      data_before: data_before,
      data_after: data_after,
      request: request
    )
  end
end
