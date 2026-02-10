# frozen_string_literal: true

class Company < ApplicationRecord
  include Discard::Model

  # Ignore removed columns
  self.ignored_columns += ["code"]

  # Relationships
  has_many :users, dependent: :nullify
  has_many :projects, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true
  validates :status, presence: true, inclusion: { in: %w[active inactive] }

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :inactive, -> { where(status: "inactive") }

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id name description status created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[users projects]
  end

  def active?
    status == "active"
  end

  # Counter cache columns are automatically maintained by Rails
  # The after_discard/after_undiscard callbacks in User and Project
  # ensure counts stay accurate even with soft deletes
end
