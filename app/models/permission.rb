# frozen_string_literal: true

class Permission < ApplicationRecord
  include Discard::Model

  has_many :roles_permissions, dependent: :destroy
  has_many :roles, through: :roles_permissions

  validates :code, presence: true, uniqueness: true, format: {
    with: /\A[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+\z/,
    message: "must follow format: namespace.resource.action (e.g., 'user_management.users.index')"
  }
  validates :name, presence: true
  validates :resource, presence: true, format: {
    with: /\A[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*\z/,
    message: "must follow format: namespace.resource (e.g., 'user_management.users')"
  }

  # Extract action from code (e.g., 'user_management.users.index' => 'index')
  def action
    code.split('.').last
  end

  # Extract namespace from resource (e.g., 'user_management.users' => 'user_management')
  def namespace
    parts = resource.split('.')
    parts.length > 1 ? parts.first : nil
  end

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id code name resource section created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[roles roles_permissions]
  end
end
