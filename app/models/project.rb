# frozen_string_literal: true

class Project < ApplicationRecord
  include Discard::Model

  # Constants
  MAX_ICON_FILE_SIZE = 500.kilobytes
  VALID_STATUSES = %w[active inactive].freeze
  DEFAULT_ICON = "bi-folder"
  VALID_ICON_CONTENT_TYPES = %w[
    image/svg+xml
    image/png
    image/jpeg
    image/webp
    image/gif
  ].freeze
  # Maximum pixel dimensions for stored icon (raster images are resized on upload)
  ICON_MAX_DIMENSION = 256

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

  # Returns the icon to display - either custom file or Bootstrap icon class
  # @return [Symbol, String] :custom if has custom icon, otherwise Bootstrap icon class
  def display_icon
    if icon_file.attached?
      :custom
    else
      icon.presence || DEFAULT_ICON
    end
  end

  # Check if this project uses a custom uploaded icon
  # @return [Boolean] true if custom icon is attached
  def custom_icon?
    icon_file.attached?
  end

  # Check if the attached icon is a raster image (not SVG)
  # @return [Boolean] true if PNG, JPEG, WEBP, or GIF
  def raster_icon?
    icon_file.attached? && icon_file.content_type != "image/svg+xml"
  end

  # Returns an optimized variant for raster icons (resized + compressed)
  # SVGs are returned as-is since they're vector and don't need resizing
  # @param size [Integer] max dimension in pixels (default: 64)
  # @return [ActiveStorage::Variant, ActiveStorage::Attached::One] the optimized icon
  def optimized_icon(size: 64)
    return icon_file unless raster_icon?

    icon_file.variant(
      resize_to_limit: [ size, size ],
      saver: { quality: 80, strip: true }
    )
  end

  private

  # Validate icon file format and size
  def icon_file_format
    return unless icon_file.attached?

    validate_icon_content_type
    validate_icon_file_size
  end

  def validate_icon_content_type
    return if VALID_ICON_CONTENT_TYPES.include?(icon_file.content_type)

    errors.add(:icon_file, "must be an image file (SVG, PNG, JPEG, WEBP, or GIF)")
  end

  def validate_icon_file_size
    return if icon_file.byte_size <= MAX_ICON_FILE_SIZE

    errors.add(:icon_file, "must be less than #{MAX_ICON_FILE_SIZE / 1024}KB")
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
