# frozen_string_literal: true

class Role < ApplicationRecord
  include Discard::Model

  has_many :users, dependent: :nullify
  has_many :roles_permissions, dependent: :destroy
  has_many :permissions, through: :roles_permissions

  validates :name, presence: true, uniqueness: true

  # Touch role when permissions change to invalidate user permission cache
  before_destroy :check_for_users
  after_touch :clear_users_permission_cache

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id name description created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[users permissions roles_permissions]
  end

  private

  def check_for_users
    return unless users.exists?

    errors.add(:base, "Cannot delete role with associated users")
    throw(:abort)
  end

  # Clear permission cache for all users with this role when role is touched
  def clear_users_permission_cache
    users.find_each(&:clear_permission_cache)
  end
end
