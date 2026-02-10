# frozen_string_literal: true

require "test_helper"

class ProjectIconTest < ActiveSupport::TestCase
  setup do
    @company = companies(:acme_corp)
    @project = Project.create!(
      name: "Test Project",
      status: "active",
      company: @company,
      icon: "bi-folder"
    )
  end

  # ============================================================================
  # TEST 1: Create project with Bootstrap icon (no custom SVG)
  # ============================================================================
  test "create project with bootstrap icon only" do
    project = Project.create!(
      name: "Bootstrap Icon Project",
      status: "active",
      company: @company,
      icon: "bi-graph-up"
    )

    assert_equal "bi-graph-up", project.icon
    assert_not project.icon_file.attached?
    assert_equal "bi-graph-up", project.display_icon
  end

  # ============================================================================
  # TEST 2: Create project with custom SVG (overrides bootstrap icon)
  # ============================================================================
  test "create project with custom svg icon" do
    svg_content = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16"><circle cx="8" cy="8" r="8"/></svg>'
    svg_file = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(svg_content),
      filename: "custom-icon.svg",
      content_type: "image/svg+xml"
    )

    project = Project.create!(
      name: "Custom SVG Project",
      status: "active",
      company: @company,
      icon: "bi-folder"
    )
    project.icon_file.attach(svg_file)

    assert project.icon_file.attached?
    assert_equal :custom, project.display_icon
  end

  # ============================================================================
  # TEST 3: Update from Bootstrap icon to custom SVG
  # ============================================================================
  test "update project from bootstrap icon to custom svg" do
    # Start with bootstrap icon only
    assert_equal "bi-folder", @project.icon
    assert_not @project.icon_file.attached?
    assert_equal "bi-folder", @project.display_icon

    # Upload custom SVG
    svg_content = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16"><rect width="16" height="16"/></svg>'
    svg_file = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(svg_content),
      filename: "new-icon.svg",
      content_type: "image/svg+xml"
    )
    @project.icon_file.attach(svg_file)

    # Custom SVG should now be used
    assert @project.icon_file.attached?
    assert_equal :custom, @project.display_icon
    # Bootstrap icon is still there but not used
    assert_equal "bi-folder", @project.icon
  end

  # ============================================================================
  # TEST 4: Update from custom SVG to Bootstrap icon (by removing SVG)
  # ============================================================================
  test "update project from custom svg to bootstrap icon by removing svg" do
    # Start with custom SVG
    svg_content = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16"><path d="M0 0h16v16H0z"/></svg>'
    svg_file = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(svg_content),
      filename: "old-icon.svg",
      content_type: "image/svg+xml"
    )
    @project.icon_file.attach(svg_file)
    @project.update!(icon: "bi-star")

    assert @project.icon_file.attached?
    assert_equal :custom, @project.display_icon

    # Remove the custom SVG
    @project.icon_file.purge

    # Now bootstrap icon should be used
    assert_not @project.icon_file.attached?
    assert_equal "bi-star", @project.display_icon
  end

  # ============================================================================
  # TEST 5: Update custom SVG with a new custom SVG
  # ============================================================================
  test "update project custom svg with new custom svg" do
    # Start with first custom SVG
    svg_content_1 = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16"><circle cx="8" cy="8" r="4"/></svg>'
    svg_file_1 = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(svg_content_1),
      filename: "icon-v1.svg",
      content_type: "image/svg+xml"
    )
    @project.icon_file.attach(svg_file_1)

    assert @project.icon_file.attached?
    assert_equal "icon-v1.svg", @project.icon_file.filename.to_s

    # Replace with new custom SVG
    svg_content_2 = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16"><rect x="2" y="2" width="12" height="12"/></svg>'
    svg_file_2 = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(svg_content_2),
      filename: "icon-v2.svg",
      content_type: "image/svg+xml"
    )
    @project.icon_file.attach(svg_file_2)

    assert @project.icon_file.attached?
    assert_equal "icon-v2.svg", @project.icon_file.filename.to_s
    assert_equal :custom, @project.display_icon
  end

  # ============================================================================
  # TEST 6: Validate only SVG files are accepted
  # ============================================================================
  test "reject non-svg file upload" do
    png_content = "\x89PNG\r\n\x1a\n" # PNG header
    png_file = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(png_content),
      filename: "icon.png",
      content_type: "image/png"
    )

    project = Project.new(
      name: "Invalid Icon Project",
      status: "active",
      company: @company
    )
    project.icon_file.attach(png_file)

    assert_not project.valid?
    assert_includes project.errors[:icon_file], "must be an SVG file"
  end

  # ============================================================================
  # TEST 7: Validate file size limit (100KB max)
  # ============================================================================
  test "reject svg file over 100kb" do
    # Create SVG content larger than 100KB
    large_svg_content = '<svg xmlns="http://www.w3.org/2000/svg">' + ("x" * 110_000) + "</svg>"
    large_svg_file = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(large_svg_content),
      filename: "large-icon.svg",
      content_type: "image/svg+xml"
    )

    project = Project.new(
      name: "Large Icon Project",
      status: "active",
      company: @company
    )
    project.icon_file.attach(large_svg_file)

    assert_not project.valid?
    assert_includes project.errors[:icon_file], "must be less than 100KB"
  end

  # ============================================================================
  # TEST 8: Default icon when none specified
  # ============================================================================
  test "display_icon returns default when no icon specified" do
    project = Project.create!(
      name: "No Icon Project",
      status: "active",
      company: @company,
      icon: nil
    )

    assert_not project.icon_file.attached?
    assert_equal "bi-folder", project.display_icon
  end
end
