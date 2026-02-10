# frozen_string_literal: true

class Dashboard < ApplicationRecord
  include Discard::Model

  # URL format validation regex (compiled once for performance)
  URL_FORMAT = URI::DEFAULT_PARSER.make_regexp(%w[http https]).freeze

  belongs_to :project
  has_and_belongs_to_many :users, join_table: :dashboards_users

  validates :name, presence: true
  validates :embed_url, presence: true, format: { with: URL_FORMAT, message: "must be a valid HTTP or HTTPS URL" }
  validates :embed_type, presence: true, inclusion: { in: %w[iframe embed_url] }
  validates :status, presence: true, inclusion: { in: %w[active inactive] }

  scope :active, -> { where(status: "active") }
  scope :inactive, -> { where(status: "inactive") }
  scope :ordered, -> { order(position: :asc, created_at: :desc) }

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id name embed_url embed_type status position project_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[project users]
  end

  def active?
    status == "active"
  end
end
