# frozen_string_literal: true

# Service for managing icon files on Active Storage attachments.
# Handles icon type switching logic and cleanup operations.
#
# Usage:
#   service = IconFileService.new(project)
#   service.handle_icon_change(params[:project])
#
class IconFileService
  # @param record [ActiveRecord::Base] record with icon_file attachment
  # @param attachment_name [Symbol] name of the attachment (default: :icon_file)
  def initialize(record, attachment_name: :icon_file)
    @record = record
    @attachment_name = attachment_name
  end

  # Handle icon type change based on form params
  # Purges existing icon file when switching to Bootstrap icon or when explicitly removed
  #
  # @param params [Hash, ActionController::Parameters] form params containing icon_type and/or remove_icon_file
  # @return [Boolean] true if any change was made
  def handle_icon_change(params)
    return false unless @record.respond_to?(@attachment_name)

    if switching_to_bootstrap?(params)
      purge_icon_file
      true
    elsif removing_icon?(params)
      purge_icon_file
      true
    else
      false
    end
  end

  # Check if switching from custom icon to Bootstrap icon
  # @param params [Hash] form params
  # @return [Boolean]
  def switching_to_bootstrap?(params)
    params_icon_type(params) == "bootstrap" && icon_attached?
  end

  # Check if user requested to remove the icon file
  # @param params [Hash] form params
  # @return [Boolean]
  def removing_icon?(params)
    params_remove_flag(params) == "1" || params_remove_flag(params) == true
  end

  # Purge the attached icon file
  # @return [void]
  def purge_icon_file
    attachment.purge if icon_attached?
  end

  # Check if icon file is currently attached
  # @return [Boolean]
  def icon_attached?
    attachment&.attached?
  rescue StandardError
    false
  end

  private

  def attachment
    @record.public_send(@attachment_name)
  end

  def params_icon_type(params)
    extract_param(params, :icon_type)
  end

  def params_remove_flag(params)
    extract_param(params, :remove_icon_file)
  end

  def extract_param(params, key)
    if params.respond_to?(:dig)
      params.dig(key) || params[key.to_s]
    else
      params[key] || params[key.to_s]
    end
  end
end
