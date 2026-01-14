# frozen_string_literal: true

class Project < ApplicationRecord
  include Discard::Model

  # Relationships
  belongs_to :created_by, class_name: "User", optional: true
  has_many :dashboards, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :code, presence: true, uniqueness: { scope: :created_by_id, conditions: -> { kept }, message: "has already been taken" }
  validates :status, presence: true, inclusion: { in: %w[active inactive] }
  validates :icon, format: { with: /\Abi-[\w-]+\z/, allow_blank: true, message: "must be a valid Bootstrap Icons class (e.g., bi-folder, bi-graph-up)" }

  scope :active, -> { where(status: "active") }
  scope :inactive, -> { where(status: "inactive") }
  scope :visible_in_sidebar, -> { where(show_in_sidebar: true) }
  scope :sidebar_ordered, -> { order(sidebar_position: :asc, name: :asc) }

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id name code description status icon show_in_sidebar sidebar_position created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[dashboards]
  end

  def active?
    status == "active"
  end

  def dashboards_count
    dashboards.kept.count
  end
end
