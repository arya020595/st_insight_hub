# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Method

  # Check if current page matches any of the given paths
  def active_nav_item?(*paths)
    paths.any? { |path| current_page?(path) }
  end

  # Check if current controller matches any of the given controller paths
  def active_controller?(*controllers)
    controllers.any? { |controller| controller_path.start_with?(controller) }
  end

  # Check if user has permission to view a menu item
  # @param permission_code [String] Full permission code (e.g., 'user_management.users.index')
  def can_view_menu?(permission_code)
    return true unless current_user # Show to guests (will be caught by authentication)

    current_user.has_permission?(permission_code)
  end

  # Returns a policy instance for the given record and policy class
  # @param record [ActiveRecord::Base] the record to authorize
  # @param policy_class [Class] the policy class to use
  # @return [ApplicationPolicy] policy instance
  def record_policy(record, policy_class)
    policy_class.new(current_user, record)
  end

  # Returns the appropriate Bootstrap badge class for an action
  # @param action [String] the action type
  # @return [String] Bootstrap badge class
  def action_badge_class(action)
    case action.to_s.downcase
    when "create"
      "success"
    when "update"
      "primary"
    when "delete"
      "danger"
    when "login"
      "info"
    when "logout"
      "secondary"
    when "view", "export"
      "warning"
    else
      "secondary"
    end
  end

  # Returns the appropriate Bootstrap badge class for a status
  # @param status [String] the status value
  # @return [String] Bootstrap badge class
  def status_badge_class(status)
    case status.to_s.downcase
    when "active"
      "success"
    when "inactive"
      "secondary"
    else
      "secondary"
    end
  end

  # Format datetime for display
  # @param datetime [DateTime] the datetime to format
  # @param format [Symbol] the format to use (:short, :long, :date_only)
  # @return [String] formatted datetime
  def format_datetime(datetime, format = :short)
    return "-" if datetime.blank?

    case format
    when :short
      datetime.strftime("%Y-%m-%d %H:%M")
    when :long
      datetime.strftime("%B %d, %Y at %I:%M %p")
    when :date_only
      datetime.strftime("%Y-%m-%d")
    else
      datetime.to_s
    end
  end

  # Returns projects visible in sidebar with their active dashboards
  # Used by sidebar partial to render dynamic menu items
  # @return [ActiveRecord::Relation] projects with dashboards eager loaded
  def sidebar_projects
    @sidebar_projects ||= Project.kept.active.visible_in_sidebar.sidebar_ordered.includes(:dashboards)
  end
end
