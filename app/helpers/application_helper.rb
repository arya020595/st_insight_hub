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

  # Returns projects visible in the sidebar with their dashboards eager loaded.
  #
  # This result is memoized in the instance variable +@sidebar_projects+ and is therefore
  # cached for the duration of the current request. The base relation includes dashboards
  # via +includes(:dashboards)+ to avoid N+1 queries when iterating over projects and
  # accessing their dashboards.
  #
  # For non-superadmin users, only projects they own (created_by) are returned.
  # Superadmin users bypass this restriction (but they don't see the BI Dashboard menu anyway).
  #
  # NOTE: This method only eager loads dashboards for the base scope defined here. If you
  # chain additional scopes on the returned relation in views or partials (for example
  # +sidebar_projects.kept.active.ordered+), Rails will build new relations and may issue
  # additional queries. In particular, further filtering or ordering does not add new
  # eager-loading associations and can reintroduce N+1 queries if dashboards or other
  # associations are accessed without explicit +includes+.
  #
  # Recommended usage:
  # - Prefer iterating directly over +sidebar_projects+ in views when possible.
  # - If you need specific filtered subsets used in multiple places, consider extracting
  #   additional helper methods or model scopes that compose the required filters together
  #   with the appropriate +includes+, instead of chaining ad-hoc scopes in the view.
  #
  # @return [ActiveRecord::Relation] projects visible in the sidebar with dashboards eager loaded
  def sidebar_projects
    @sidebar_projects ||= begin
      base_scope = Project.kept.active.visible_in_sidebar.sidebar_ordered.includes(:dashboards)

      # Non-superadmin users only see projects they own (created_by)
      if current_user && !current_user.superadmin?
        base_scope.where(created_by_id: current_user.id)
      else
        base_scope
      end
    end
  end

  # Returns a safe URL by validating the scheme
  # Only allows http and https protocols to prevent javascript: or data: URLs
  # @param url [String] URL to validate
  # @return [String, nil] Safe URL or nil if invalid
  def safe_url(url)
    return nil if url.blank?

    uri = URI.parse(url)
    %w[http https].include?(uri.scheme) ? url : nil
  rescue URI::InvalidURIError
    nil
  end

  # Returns the minimum password length requirement for a given model
  # @param model [ActiveRecord::Base, Class] the model instance or class to check
  # @return [Integer] minimum password length (defaults to 6 if not found)
  def minimum_password_length(model = User)
    klass = model.is_a?(Class) ? model : model.class
    length_validator = klass.validators_on(:password).find { |v| v.is_a?(ActiveModel::Validations::LengthValidator) }
    length_validator&.options&.dig(:minimum) || 6
  end
end
