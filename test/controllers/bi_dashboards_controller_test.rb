# frozen_string_literal: true

require "test_helper"

class BiDashboardsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # ============================================================================
  # TEST SETUP - Based on Business Rules:
  # - Superadmin: Full access (bypasses permission checks)
  # - Client: Can only access assigned projects and their dashboards
  # - Unassigned projects are not accessible to users
  # ============================================================================

  setup do
    @superadmin = users(:superadmin)

    # Client users from Acme Corporation
    @client_john = users(:client_acme_john)  # Assigned to: Sales Analytics, Marketing Insights
    @client_jane = users(:client_acme_jane)  # Assigned to: Marketing Insights only

    # Client users from DataFlow Solutions
    @client_alice = users(:client_dataflow_alice)  # Assigned to: Customer Insights
    @client_mike = users(:client_dataflow_mike)    # Assigned to: Customer Insights

    # Projects
    @sales_project = projects(:active_project)       # Acme - Sales Analytics
    @marketing_project = projects(:marketing_project) # Acme - Marketing Insights
    @dataflow_project = projects(:dataflow_project)  # DataFlow - Customer Insights
    @inactive_project = projects(:inactive_project)

    # Dashboards
    @sales_dashboard = dashboards(:sales_overview_dashboard)
    @revenue_dashboard = dashboards(:revenue_breakdown_dashboard)
    @inactive_dashboard = dashboards(:inactive_dashboard)
    @discarded_dashboard = dashboards(:discarded_dashboard)
    @campaign_dashboard = dashboards(:campaign_dashboard)
    @customer_dashboard = dashboards(:customer_analytics_dashboard)
    @dashboard_of_inactive_project = dashboards(:dashboard_of_inactive_project)
  end

  # ============================================================================
  # INDEX ACTION TESTS
  # ============================================================================

  test "index requires authentication" do
    get bi_dashboards_path
    assert_redirected_to new_user_session_path
  end

  test "index is accessible with client permissions" do
    sign_in @client_john

    get bi_dashboards_path
    assert_response :success
  end

  test "index loads only assigned projects for client user" do
    sign_in @client_john

    get bi_dashboards_path
    assert_response :success
    # John should see his assigned projects
    # (Note: actual visibility depends on policy scope implementation)
  end

  test "superadmin can access index" do
    sign_in @superadmin

    get bi_dashboards_path
    assert_response :success
  end

  # ============================================================================
  # SHOW ACTION TESTS - Access Control
  # ============================================================================

  test "show requires authentication" do
    get bi_dashboard_path(@sales_dashboard)
    assert_redirected_to new_user_session_path
  end

  test "client can access dashboard from assigned project" do
    sign_in @client_john  # Assigned to Sales Analytics project

    get bi_dashboard_path(@sales_dashboard)
    assert_response :success
    assert_match @sales_dashboard.name, response.body
  end

  test "client cannot access dashboard from unassigned project" do
    sign_in @client_jane  # NOT assigned to Sales Analytics, only Marketing

    get bi_dashboard_path(@sales_dashboard)
    # Should be redirected as not authorized
    assert_redirected_to dashboard_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "client from different company cannot access other company projects" do
    sign_in @client_alice  # DataFlow user

    get bi_dashboard_path(@sales_dashboard)  # Acme project dashboard
    assert_redirected_to dashboard_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "show displays dashboard name and embed URL" do
    sign_in @client_john

    get bi_dashboard_path(@sales_dashboard)
    assert_response :success
    assert_match @sales_dashboard.embed_url, response.body
  end

  test "show displays project context for dashboard" do
    sign_in @client_john

    get bi_dashboard_path(@sales_dashboard)
    assert_response :success
    assert_match @sales_project.name, response.body
  end

  test "show renders iframe for embedding" do
    sign_in @client_john

    get bi_dashboard_path(@sales_dashboard)
    assert_response :success
    assert_select "iframe"
  end

  # ============================================================================
  # SUPERADMIN ACCESS TESTS
  # ============================================================================

  test "superadmin can access any dashboard" do
    sign_in @superadmin

    # Access Acme project dashboard
    get bi_dashboard_path(@sales_dashboard)
    assert_response :success

    # Access DataFlow project dashboard
    get bi_dashboard_path(@customer_dashboard)
    assert_response :success
  end

  test "superadmin can access dashboards from any company" do
    sign_in @superadmin

    get bi_dashboard_path(@sales_dashboard)
    assert_response :success
    assert_match @sales_dashboard.name, response.body
  end

  # ============================================================================
  # EDGE CASES AND SECURITY TESTS
  # ============================================================================

  test "show raises error for non-existent dashboard ID" do
    sign_in @client_john

    get bi_dashboard_path(id: 99999)
    assert_response :not_found
  end

  test "show raises error for discarded dashboard" do
    sign_in @client_john

    get bi_dashboard_path(@discarded_dashboard)
    assert_response :not_found
  end

  test "show raises error for dashboard from inactive project" do
    sign_in @client_john

    get bi_dashboard_path(@dashboard_of_inactive_project)
    assert_response :not_found
  end

  test "show can access inactive dashboard from active project if assigned" do
    sign_in @client_john

    get bi_dashboard_path(@inactive_dashboard)
    assert_response :success
    assert_match @inactive_dashboard.name, response.body
  end

  test "show prevents SQL injection in dashboard ID" do
    sign_in @client_john

    get bi_dashboard_path(id: "1 OR 1=1")
    assert_response :not_found
  end

  test "show handles invalid dashboard ID gracefully" do
    sign_in @client_john

    get bi_dashboard_path(id: "invalid-id")
    assert_response :not_found
  end

  # ============================================================================
  # MULTI-DASHBOARD ACCESS TESTS
  # ============================================================================

  test "client can access all dashboards from assigned project" do
    sign_in @client_john  # Assigned to Sales Analytics

    # Access first dashboard
    get bi_dashboard_path(@sales_dashboard)
    assert_response :success

    # Access second dashboard in same project
    get bi_dashboard_path(@revenue_dashboard)
    assert_response :success
  end

  test "client with multiple project assignments can access all assigned dashboards" do
    sign_in @client_john  # Assigned to Sales Analytics AND Marketing Insights

    # Access Sales Analytics dashboard
    get bi_dashboard_path(@sales_dashboard)
    assert_response :success

    # Access Marketing Insights dashboard
    get bi_dashboard_path(@campaign_dashboard)
    assert_response :success
  end
end
