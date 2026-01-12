# frozen_string_literal: true

class AuditLog < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :auditable, polymorphic: true, optional: true

  validates :module_name, presence: true
  validates :action, presence: true, inclusion: { in: ACTIONS }

  # Available actions
  ACTIONS = %w[create update delete login logout view export].freeze

  scope :recent, -> { order(created_at: :desc) }
  scope :by_action, ->(action) { where(action: action) if action.present? }
  scope :by_module, ->(mod) { where(module_name: mod) if mod.present? }
  scope :by_user, ->(user_id) { where(user_id: user_id) if user_id.present? }
  scope :date_range, ->(start_date, end_date) {
    where(created_at: start_date.beginning_of_day..end_date.end_of_day) if start_date.present? && end_date.present?
  }

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id user_id user_name module_name action auditable_type auditable_id summary ip_address created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user auditable]
  end

  # Create an audit log entry
  def self.log(action:, module_name:, user: nil, auditable: nil, summary: nil, data_before: nil, data_after: nil, request: nil)
    create!(
      user: user,
      user_name: user&.name || user&.email,
      module_name: module_name,
      action: action,
      auditable: auditable,
      summary: summary,
      data_before: data_before,
      data_after: data_after,
      ip_address: request&.remote_ip,
      user_agent: request&.user_agent
    )
  end
end
