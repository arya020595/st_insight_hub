# frozen_string_literal: true

# RansackMultiSortHelper
#
# Provides view helpers for rendering multi-sort UI components and pagination.
#
# Usage:
#   <%= per_page_selector(current: params[:per_page]) %>
#   <%== pagy_bootstrap_nav(@pagy) %>
module RansackMultiSortHelper
  # Default per-page options for pagination selector
  DEFAULT_PER_PAGE_OPTIONS = [ 10, 25, 50, 100 ].freeze

  # Renders a per-page dropdown that preserves search params
  #
  # @param per_page_options [Array<Integer>] Available per-page options
  # @param current [Integer] Currently selected per-page value
  # @return [String] HTML string
  def per_page_selector(per_page_options: DEFAULT_PER_PAGE_OPTIONS, current: nil)
    current ||= Pagy.options[:limit]
    form_with url: request.path, method: :get, local: true,
              html: { class: "d-inline" } do |f|
      concat hidden_search_fields
      concat render_per_page_select(f, per_page_options, current)
    end
  end

  # Renders Bootstrap-styled pagination nav (Pagy object helper)
  # Usage in views (safe output):
  #   <%== pagy_bootstrap_nav(@pagy) %>
  #   <%== pagy_bootstrap_nav(@pagy, aria_label: 'Product pages') %>
  #
  # @param pagy [Pagy] Pagy instance
  # @param aria_label [String] Optional ARIA label for accessibility
  # @param options [Hash] Additional options passed to series_nav
  # @return [String] HTML string
  def pagy_bootstrap_nav(pagy, aria_label: nil, **options)
    return "" unless pagy

    options[:aria_label] ||= aria_label if aria_label

    pagy.series_nav(:bootstrap, **options)
  end

  private

  # Renders per-page select element
  #
  # @param form [ActionView::Helpers::FormBuilder] Form builder
  # @param options [Array<Integer>] Per-page options
  # @param current [Integer] Current value
  # @return [String] HTML string
  def render_per_page_select(form, options, current)
    form.select(:per_page,
                options_for_select(options, current),
                {},
                { class: "form-select form-select-sm d-inline-block",
                  style: "width: auto;",
                  onchange: "this.form.submit()" })
  end

  # Generates hidden fields for all search params except sorts
  #
  # @return [String] HTML safe string with hidden fields
  def hidden_search_fields
    return "" unless params[:q]

    generate_hidden_fields.compact.join.html_safe
  end

  # Generates array of hidden field tags
  #
  # @return [Array<String>] Array of hidden field HTML strings
  def generate_hidden_fields
    params[:q].to_unsafe_h.map do |key, value|
      next if key.to_s == "s"

      hidden_field_tag "q[#{key}]", value
    end
  end
end
