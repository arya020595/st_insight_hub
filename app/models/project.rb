# frozen_string_literal: true

class Project < ApplicationRecord
  include Discard::Model

  # Relationships
  belongs_to :company, counter_cache: true
  has_many :dashboards, dependent: :destroy
  has_and_belongs_to_many :users, join_table: :projects_users

  # Validations
  validates :name, presence: true
  validates :code, presence: true, uniqueness: { scope: :company_id, conditions: -> { kept } }
  validates :status, presence: true, inclusion: { in: %w[active inactive] }
  validate :users_belong_to_same_company

  # Update counter cache when project is discarded/undiscarded
  after_discard :decrement_company_projects_count
  after_undiscard :increment_company_projects_count

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

  # Decrement company projects_count when project is discarded
  def decrement_company_projects_count
    company&.decrement!(:projects_count)
  end

  # Increment company projects_count when project is undiscarded
  def increment_company_projects_count
    company&.increment!(:projects_count)
  end

  # Validate that all assigned users belong to the project's company
  def users_belong_to_same_company
    return if users.empty? || company_id.blank?

    invalid_users = users.select { |user| user.company_id != company_id }
    if invalid_users.any?
      errors.add(:users, "must belong to the same company as the project")
    end
  end
end
