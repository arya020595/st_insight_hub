# frozen_string_literal: true

require "test_helper"

class BiDashboardsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @superadmin_user = users(:superadmin)
    @admin_user = users(:admin)
    @viewer_user = users(:viewer)
    @no_permission_user = users(:no_permission)

    @active_dashboard = dashboards(:active_dashboard)
    @inactive_dashboard = dashboards(:inactive_dashboard)
    @discarded_dashboard = dashboards(:discarded_dashboard)
    @dashboard_of_inactive_project = dashboards(:dashboard_of_inactive_project)
    @active_project = projects(:active_project)
  end

  # ============================================================================
  # INDEX ACTION TESTS
  # ============================================================================

  test "index requires authentication" do
    get bi_dashboards_path
    assert_redirected_to new_user_session_path
  end

  test "index requires bi_dashboards.index permission" do
    sign_in @no_permission_user

    get bi_dashboards_path
    # App redirects with flash message instead of 403
    assert_redirected_to dashboard_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "index is accessible with proper permissions" do
    sign_in @viewer_user

    get bi_dashboards_path
    assert_response :success
  end

  test "index loads active projects with dashboards" do
    sign_in @admin_user

    get bi_dashboards_path
    assert_response :success
    # Check that active project is visible in the response
    assert_match @active_project.name, response.body
  end

  test "superadmin can access index" do
    sign_in @superadmin_user

    get bi_dashboards_path
    assert_response :success
  end

  # ============================================================================
  # SHOW ACTION TESTS
  # ============================================================================

  test "show requires authentication" do
    get bi_dashboard_path(@active_dashboard)
    assert_redirected_to new_user_session_path
  end

  test "show requires bi_dashboards.index permission" do
    sign_in @no_permission_user

    get bi_dashboard_path(@active_dashboard)
    # App redirects with flash message instead of raising error
    assert_redirected_to dashboard_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "show is accessible with proper permissions for active dashboard" do
    sign_in @viewer_user

    get bi_dashboard_path(@active_dashboard)
    assert_response :success
    # Verify dashboard content is displayed
    assert_match @active_dashboard.name, response.body
  end

  test "show displays dashboard name and embed URL" do
    sign_in @admin_user

    get bi_dashboard_path(@active_dashboard)
    assert_response :success
    # Check embed URL is in the iframe
    assert_match @active_dashboard.embed_url, response.body
  end

  test "show raises error for non-existent dashboard ID" do
    sign_in @admin_user

    get bi_dashboard_path(id: 99999)
    assert_response :not_found
  end

  test "show raises error for discarded dashboard" do
    sign_in @admin_user

    get bi_dashboard_path(@discarded_dashboard)
    assert_response :not_found
  end

  test "show raises error for dashboard from inactive project" do
    sign_in @admin_user

    get bi_dashboard_path(@dashboard_of_inactive_project)
    assert_response :not_found
  end

  test "show can access inactive dashboard from active project" do
    sign_in @admin_user

    # The controller allows inactive dashboards if project is active and visible
    get bi_dashboard_path(@inactive_dashboard)
    assert_response :success
    assert_match @inactive_dashboard.name, response.body
  end

  test "show displays project context for dashboard" do
    sign_in @admin_user

    get bi_dashboard_path(@active_dashboard)
    assert_response :success
    # The project name should be visible in the page
    assert_match @active_project.name, response.body
  end

  test "show renders iframe for embedding" do
    sign_in @admin_user

    get bi_dashboard_path(@active_dashboard)
    assert_response :success
    assert_select "iframe"
  end

  test "superadmin can access show" do
    sign_in @superadmin_user

    get bi_dashboard_path(@active_dashboard)
    assert_response :success
    assert_match @active_dashboard.name, response.body
  end

  # ============================================================================
  # SECURITY TESTS
  # ============================================================================

  test "show prevents SQL injection in dashboard ID" do
    sign_in @admin_user

    get bi_dashboard_path(id: "1 OR 1=1")
    assert_response :not_found
  end

  test "show only returns kept dashboards via Dashboard.kept scope" do
    sign_in @admin_user

    # Verify discarded dashboard cannot be accessed
    assert @discarded_dashboard.discarded?

    get bi_dashboard_path(@discarded_dashboard)
    assert_response :not_found
  end

  test "show handles invalid dashboard ID gracefully" do
    sign_in @admin_user

    get bi_dashboard_path(id: "invalid-id")
    assert_response :not_found
  end

  # ============================================================================
  # PERMISSION CACHING TESTS
  # ============================================================================

  test "user with cached permissions can access show" do
    sign_in @viewer_user

    # First request to cache permissions
    get bi_dashboard_path(@active_dashboard)
    assert_response :success

    # Second request using cached permissions
    get bi_dashboard_path(@inactive_dashboard)
    assert_response :success
  end
end
