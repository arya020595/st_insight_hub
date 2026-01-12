# frozen_string_literal: true

class Dashboard < ApplicationRecord
  include Discard::Model

  belongs_to :project

  validates :name, presence: true
  validates :embed_url, presence: true
  validates :embed_type, presence: true, inclusion: { in: %w[iframe embed_url] }
  validates :status, presence: true, inclusion: { in: %w[active inactive] }

  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
  scope :ordered, -> { order(position: :asc, created_at: :desc) }

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id name embed_url embed_type status position project_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[project]
  end

  def active?
    status == 'active'
  end
end
