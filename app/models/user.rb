# frozen_string_literal: true

class User < ApplicationRecord
  include Discard::Model

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  belongs_to :role, optional: true
  has_many :audit_logs, dependent: :nullify

  validates :name, presence: true

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id email name role_id created_at updated_at current_sign_in_at last_sign_in_at sign_in_count]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[role audit_logs]
  end

  # Check if user has a specific permission code
  # Superadmin role bypasses all permission checks
  # Example: user.has_permission?("user_management.users.index")
  def has_permission?(code)
    return false unless role
    return true if superadmin?

    @permission_codes ||= role.permissions.pluck(:code)
    @permission_codes.include?(code)
  end

  # Check if user has any permission for a resource
  # Example: user.has_resource_permission?("user_management.users")
  def has_resource_permission?(resource)
    return false unless role
    return true if superadmin?

    @permission_codes ||= role.permissions.pluck(:code)
    @permission_codes.any? { |code| code.start_with?("#{resource}.") }
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
end
