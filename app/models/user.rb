# frozen_string_literal: true

class User < ApplicationRecord
  include Discard::Model

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  belongs_to :role, optional: true
  belongs_to :company, optional: true, counter_cache: true
  has_many :audit_logs, dependent: :nullify
  has_and_belongs_to_many :dashboards, join_table: :dashboards_users

  validates :name, presence: true
  validate :company_required_for_client_role

  # Update counter cache when user is discarded/undiscarded
  after_discard :decrement_company_users_count
  after_undiscard :increment_company_users_count

  # Clear cached permissions when role changes
  after_save :clear_permission_cache, if: :saved_change_to_role_id?
  # Clear dashboard assignments when company changes
  before_save :clear_dashboards_on_company_change, if: :will_save_change_to_company_id?

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id email name role_id company_id created_at updated_at current_sign_in_at last_sign_in_at sign_in_count]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[role company audit_logs dashboards]
  end

  # Check if user has a specific permission code
  # Superadmin role bypasses all permission checks
  # Example: user.has_permission?("user_management.users.index")
  def has_permission?(code)
    return false unless role
    return true if superadmin?

    permission_codes.include?(code)
  end

  # Check if user has any permission for a resource
  # Example: user.has_resource_permission?("user_management.users")
  def has_resource_permission?(resource)
    return false unless role
    return true if superadmin?

    permission_codes.any? { |code| code.start_with?("#{resource}.") }
  end

  # Clear the permission cache (useful when role permissions are updated)
  def clear_permission_cache
    @permission_codes = nil
  end

  # Check if user is superadmin (bypasses all permission checks)
  def superadmin?
    role&.name&.casecmp("superadmin")&.zero?
  end

  # Get user's first accessible path based on their permissions
  def first_accessible_path
    return :dashboard_path if superadmin?

    # Check dashboard access first
    return :dashboard_path if has_permission?("dashboard.index")

    # Check other permissions in order of priority
    return :bi_dashboards_path if has_permission?("bi_dashboards.index")
    return :user_management_users_path if has_permission?("user_management.users.index")
    return :audit_logs_path if has_permission?("audit_logs.index")

    # Default fallback
    :dashboard_path
  end

  private

  # Validate that Client role users must have a company
  def company_required_for_client_role
    return if role.blank?
    return if superadmin?
    return if company_id.present?

    errors.add(:company_id, "must be selected for Client role") unless role.name == "Superadmin"
  end

  # Clear dashboard assignments when company changes
  def clear_dashboards_on_company_change
    dashboards.clear if persisted?
  end

  # Decrement company users_count when user is discarded
  def decrement_company_users_count
    company&.decrement!(:users_count)
  end

  # Increment company users_count when user is undiscarded
  def increment_company_users_count
    company&.increment!(:users_count)
  end

  # Cache permission codes with role/permissions as cache key
  # Cache is automatically invalidated when role or its permissions change
  def permission_codes
    # Use a composite cache key based on role ID and role's updated_at timestamp
    # This ensures cache invalidation when role's permissions are modified
    cache_key = "user_#{id}_role_#{role.id}_#{role.updated_at.to_i}"

    @permission_codes = nil if @cache_key != cache_key
    @cache_key = cache_key

    @permission_codes ||= begin
      # Use loaded association if available (eager loaded in controller)
      # Otherwise, use pluck for performance
      if role.association(:permissions).loaded?
        role.permissions.map(&:code)
      else
        role.permissions.pluck(:code)
      end
    end
  end
end
