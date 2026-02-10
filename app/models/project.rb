# frozen_string_literal: true

class Project < ApplicationRecord
  include Discard::Model

  # Constants
  MAX_ICON_FILE_SIZE = 100.kilobytes
  VALID_STATUSES = %w[active inactive].freeze
  DEFAULT_ICON = "bi-folder"

  # Ignore removed columns
  self.ignored_columns += [ "code" ]

  # Active Storage attachment for custom icon
  has_one_attached :icon_file

  # Relationships
  belongs_to :company, counter_cache: true
  has_many :dashboards, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :status, presence: true, inclusion: { in: VALID_STATUSES }
  validate :icon_file_format, if: -> { icon_file.attached? }

  # Update counter cache when project is discarded/undiscarded
  after_discard :decrement_company_projects_count
  after_undiscard :increment_company_projects_count

  scope :active, -> { where(status: "active") }
  scope :inactive, -> { where(status: "inactive") }
  scope :visible_in_sidebar, -> { where(show_in_sidebar: true) }
  scope :sidebar_ordered, -> { order(sidebar_position: :asc, name: :asc) }

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id name description status icon show_in_sidebar sidebar_position company_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[dashboards company]
  end

  def active?
    status == "active"
  end

  def dashboards_count
    dashboards.kept.count
  end

  # Returns the icon to display - either custom SVG or Bootstrap icon class
  # @return [Symbol, String] :custom if has custom icon, otherwise Bootstrap icon class
  def display_icon
    if icon_file.attached?
      :custom
    else
      icon.presence || DEFAULT_ICON
    end
  end

  # Check if this project uses a custom SVG icon
  # @return [Boolean] true if custom icon is attached
  def custom_icon?
    icon_file.attached?
  end

  private

  # Validate icon file is SVG format and within size limit
  def icon_file_format
    return unless icon_file.attached?

    validate_icon_content_type
    validate_icon_file_size
  end

  def validate_icon_content_type
    return if icon_file.content_type == "image/svg+xml"

    errors.add(:icon_file, "must be an SVG file")
  end

  def validate_icon_file_size
    return if icon_file.byte_size <= MAX_ICON_FILE_SIZE

    errors.add(:icon_file, "must be less than 100KB")
  end

  # Decrement company projects_count when project is discarded
  def decrement_company_projects_count
    company&.decrement!(:projects_count)
  end

  # Increment company projects_count when project is undiscarded
  def increment_company_projects_count
    company&.increment!(:projects_count)
  end
end
