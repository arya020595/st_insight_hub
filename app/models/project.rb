# frozen_string_literal: true

class Project < ApplicationRecord
  include Discard::Model

  # Relationships
  belongs_to :company
  has_many :dashboards, dependent: :destroy
  has_and_belongs_to_many :users, join_table: :projects_users

  # Validations
  validates :name, presence: true
  validates :code, presence: true, uniqueness: { scope: :company_id, conditions: -> { kept } }
  validates :status, presence: true, inclusion: { in: %w[active inactive] }
  validates :icon, format: { with: /\Abi-[\w-]+\z/, allow_blank: true, message: "must be a valid Bootstrap Icons class (e.g., bi-folder, bi-graph-up)" }
  validate :users_belong_to_same_company

  scope :active, -> { where(status: "active") }
  scope :inactive, -> { where(status: "inactive") }
  scope :visible_in_sidebar, -> { where(show_in_sidebar: true) }
  scope :sidebar_ordered, -> { order(sidebar_position: :asc, name: :asc) }

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id name code description status icon show_in_sidebar sidebar_position company_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[dashboards company users]
  end

  def active?
    status == "active"
  end

  def dashboards_count
    dashboards.kept.count
  end

  private

  # Validate that all assigned users belong to the project's company
  def users_belong_to_same_company
    return if users.empty? || company_id.blank?

    invalid_users = users.select { |user| user.company_id != company_id }
    if invalid_users.any?
      errors.add(:users, "must belong to the same company as the project")
    end
  end
end
