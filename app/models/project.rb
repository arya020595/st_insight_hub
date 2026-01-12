# frozen_string_literal: true

class Project < ApplicationRecord
  include Discard::Model

  has_many :dashboards, dependent: :destroy

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: %w[active inactive] }

  scope :active, -> { where(status: "active") }
  scope :inactive, -> { where(status: "inactive") }

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id name code description status created_at updated_at]
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
