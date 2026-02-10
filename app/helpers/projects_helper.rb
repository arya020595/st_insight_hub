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
    project.icon_file.attached?
  rescue StandardError
    false
  end

  # Determines if the form should show SVG section by default
  # @param project [Project] the project being edited
  # @return [Boolean] true if project has existing SVG
  def show_svg_section?(project)
    project.persisted? && project_has_custom_icon?(project)
  end

  # Returns the initial icon type for the form
  # @param project [Project] the project being edited
  # @return [String] 'svg' or 'bootstrap'
  def initial_icon_type(project)
    show_svg_section?(project) ? "svg" : "bootstrap"
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

  # Renders a custom SVG icon from Active Storage
  # @param project [Project] the project with attached icon
  # @param size [String] CSS size
  # @param css_class [String] additional CSS classes
  # @return [String] HTML img tag
  def render_custom_icon(project, size:, css_class:)
    image_tag(
      rails_blob_path(project.icon_file, disposition: :inline, only_path: true),
      class: "project-custom-icon #{css_class}".strip,
      style: "width: #{size}; height: #{size}; vertical-align: -0.125em;",
      alt: "#{project.name} icon"
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
