# frozen_string_literal: true

module ProjectsHelper
  # Default Bootstrap icon when no icon is specified
  DEFAULT_ICON = "bi-folder"

  # Pattern for valid Bootstrap icon class names
  BOOTSTRAP_ICON_PATTERN = /\Abi-[\w-]+\z/

  # Renders a project icon - either custom SVG or Bootstrap icon
  # @param project [Project] the project to render icon for
  # @param size [String] CSS size for custom icons (default: "1em")
  # @param css_class [String] additional CSS classes (default: "me-2")
  # @return [String] HTML for the icon
  def project_icon(project, size: "1em", css_class: "me-2")
    if project_has_custom_icon?(project)
      render_custom_icon(project, size: size, css_class: css_class)
    else
      render_bootstrap_icon(project.icon, css_class: css_class)
    end
  end

  # Check if project has a valid attached custom icon
  # @param project [Project] the project to check
  # @return [Boolean] true if project has attached icon file
  def project_has_custom_icon?(project)
    project.icon_file&.attached? || false
  end
  # Determines if the form should show custom icon section by default
  # @param project [Project] the project being edited
  # @return [Boolean] true if project has existing custom icon
  def show_custom_icon_section?(project)
    project.persisted? && project_has_custom_icon?(project)
  end

  # Legacy alias for backward compatibility
  alias_method :show_svg_section?, :show_custom_icon_section?

  # Returns the initial icon type for the form
  # @param project [Project] the project being edited
  # @return [String] 'custom' or 'bootstrap'
  def initial_icon_type(project)
    show_custom_icon_section?(project) ? "custom" : "bootstrap"
  end

  # Returns a sanitized Bootstrap icon class
  # @param icon_class [String] the icon class to sanitize
  # @return [String] sanitized icon class or default
  def sanitize_bootstrap_icon(icon_class)
    raw_icon = icon_class.to_s.strip

    return DEFAULT_ICON if raw_icon.blank?

    if raw_icon.match?(BOOTSTRAP_ICON_PATTERN)
      raw_icon
    elsif raw_icon.match?(/\Abi\s+bi-[\w-]+\z/)
      # Handle "bi bi-folder" format - extract just the icon class
      raw_icon.split.last
    else
      DEFAULT_ICON
    end
  end

  private

  # Renders a custom icon from Active Storage
  # Uses optimized variants for raster images (PNG, JPEG, WEBP, GIF)
  # SVGs are served as-is (vector, no resizing needed)
  # @param project [Project] the project with attached icon
  # @param size [String] CSS size
  # @param css_class [String] additional CSS classes
  # @return [String] HTML img tag
  def render_custom_icon(project, size:, css_class:)
    icon_source = if project.raster_icon?
      # Serve optimized variant: resized to 64px, quality 80, stripped metadata
      project.optimized_icon(size: 64)
    else
      # SVG: serve original blob directly
      project.icon_file
    end

    # ActiveStorage::Variant uses rails_representation_path; Blob uses rails_blob_path
    icon_url = if icon_source.respond_to?(:processed)
      rails_representation_path(icon_source, only_path: true, disposition: :inline)
    else
      rails_blob_path(icon_source, disposition: :inline, only_path: true)
    end

    image_tag(
      icon_url,
      class: "project-custom-icon #{css_class}".strip,
      style: "width: #{size}; height: #{size}; vertical-align: -0.125em; object-fit: contain;",
      alt: "#{project.name} icon",
      loading: "lazy"
    )
  end

  # Renders a Bootstrap icon
  # @param icon_class [String] the Bootstrap icon class
  # @param css_class [String] additional CSS classes
  # @return [String] HTML i tag
  def render_bootstrap_icon(icon_class, css_class:)
    safe_icon = sanitize_bootstrap_icon(icon_class)
    tag.i(class: "bi #{safe_icon} #{css_class}".strip)
  end
end
