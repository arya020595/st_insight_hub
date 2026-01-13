# frozen_string_literal: true

# Helper module for generating modal-related attributes and configurations
# Follows Single Responsibility Principle - handles only modal attribute generation
module ModalHelper
  # Valid Bootstrap modal sizes
  MODAL_SIZES = %w[modal-sm modal-md modal-lg modal-xl modal-fullscreen].freeze
  DEFAULT_MODAL_SIZE = 'modal-lg'

  # Generates data attributes for a link that opens a modal
  # This centralizes the modal trigger configuration in one place (DRY)
  #
  # @param size [String] Bootstrap modal size class (modal-sm, modal-md, modal-lg, modal-xl, modal-fullscreen)
  # @param frame [String] Turbo frame ID to target (default: 'modal')
  # @param additional_data [Hash] Any additional data attributes
  # @return [Hash] Data attributes hash for link_to
  #
  # Example usage:
  #   <%= link_to "Edit", edit_path(record), class: "btn", **modal_link_data(size: "modal-xl") %>
  #   # Generates: data-turbo-frame="modal" data-modal-size="modal-xl"
  def modal_link_data(size: DEFAULT_MODAL_SIZE, frame: 'modal', **additional_data)
    validated_size = MODAL_SIZES.include?(size) ? size : DEFAULT_MODAL_SIZE

    {
      data: {
        turbo_frame: frame,
        modal_size: validated_size
      }.merge(additional_data)
    }
  end

  # Generates modal configuration for shared modal partial
  # This follows Open/Closed Principle - easy to extend with new options
  #
  # @param id [String] Modal DOM ID (required, must be unique on page)
  # @param default_size [String] Default Bootstrap modal size class
  # @param frame_id [String] Turbo frame ID (default: 'modal')
  # @param backdrop [String] Bootstrap backdrop option ('static' or true/false)
  # @param keyboard [Boolean] Allow keyboard ESC to close modal
  # @param centered [Boolean] Vertically center the modal
  # @return [Hash] Configuration hash for modal partial
  #
  # Example usage:
  #   <%= render "shared/modal", **modal_config(
  #         id: "workOrderModal",
  #         default_size: "modal-lg",
  #         centered: true
  #       ) %>
  def modal_config(id:, default_size: DEFAULT_MODAL_SIZE, frame_id: 'modal',
                   backdrop: 'static', keyboard: false, centered: true)
    validated_size = MODAL_SIZES.include?(default_size) ? default_size : DEFAULT_MODAL_SIZE

    {
      modal_id: id,
      default_size: validated_size,
      frame_id: frame_id,
      backdrop: backdrop,
      keyboard: keyboard,
      centered: centered
    }
  end

  # Returns all available modal sizes for select dropdowns or documentation
  # @return [Array<String>] List of valid Bootstrap modal size classes
  def available_modal_sizes
    MODAL_SIZES
  end

  # Checks if a given size is valid
  # @param size [String] The size class to validate
  # @return [Boolean] True if size is valid
  def valid_modal_size?(size)
    MODAL_SIZES.include?(size)
  end
end
