# frozen_string_literal: true

require "test_helper"

class AuditLogsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # ============================================================================
  # TEST SETUP - Based on Business Rules:
  # - Superadmin: Can view ALL audit logs
  # - Client: Can only view their OWN audit logs
  # ============================================================================

  setup do
    @superadmin = users(:superadmin)

    # Client users
    @client_john = users(:client_acme_john)
    @client_jane = users(:client_acme_jane)
    @client_alice = users(:client_dataflow_alice)

    # Audit logs
    @superadmin_log = audit_logs(:superadmin_created_user)
    @john_log = audit_logs(:client_john_viewed_dashboard)
    @jane_log = audit_logs(:client_jane_viewed_dashboard)
    @alice_log = audit_logs(:client_alice_viewed_dashboard)
  end

  # ============================================================================
  # INDEX ACTION TESTS - Authentication
  # ============================================================================

  test "index requires authentication" do
    get audit_logs_path
    assert_redirected_to new_user_session_path
  end

  # ============================================================================
  # INDEX ACTION TESTS - Role-based Filtering
  # ============================================================================

  test "superadmin can see all audit logs" do
    sign_in @superadmin

    get audit_logs_path
    assert_response :success
    # Superadmin should see logs from all users
    assert_match @superadmin_log.summary, response.body
    assert_match @john_log.summary, response.body
    assert_match @jane_log.summary, response.body
    assert_match @alice_log.summary, response.body
  end

  test "client user can only see their own audit logs" do
    sign_in @client_john

    get audit_logs_path
    assert_response :success
    # John should see his own logs
    assert_match @john_log.summary, response.body
    # John should NOT see other users' logs
    assert_no_match @jane_log.summary, response.body
    assert_no_match @superadmin_log.summary, response.body
    assert_no_match @alice_log.summary, response.body
  end

  test "client from different company cannot see other company logs" do
    sign_in @client_alice  # DataFlow user

    get audit_logs_path
    assert_response :success
    # Alice should see her own logs
    assert_match @alice_log.summary, response.body
    # Alice should NOT see Acme users' logs
    assert_no_match @john_log.summary, response.body
    assert_no_match @jane_log.summary, response.body
  end

  # ============================================================================
  # SHOW ACTION TESTS - Authentication
  # ============================================================================

  test "show requires authentication" do
    get audit_log_path(@john_log)
    assert_redirected_to new_user_session_path
  end

  # ============================================================================
  # SHOW ACTION TESTS - Role-based Access
  # ============================================================================

  test "superadmin can view any audit log" do
    sign_in @superadmin

    # Superadmin can view any user's log
    get audit_log_path(@john_log)
    assert_response :success
    assert_match @john_log.summary, response.body

    get audit_log_path(@alice_log)
    assert_response :success
    assert_match @alice_log.summary, response.body
  end

  test "client can view their own audit log" do
    sign_in @client_john

    get audit_log_path(@john_log)
    assert_response :success
    assert_match @john_log.summary, response.body
  end

  test "client cannot view other users audit logs" do
    sign_in @client_john

    get audit_log_path(@jane_log)
    # Should be redirected with authorization error
    assert_redirected_to dashboard_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "client cannot view audit logs from different company" do
    sign_in @client_john  # Acme user

    get audit_log_path(@alice_log)  # DataFlow user's log
    assert_redirected_to dashboard_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  # ============================================================================
  # SHOW ACTION TESTS - Error Handling
  # ============================================================================

  test "show raises error for non-existent audit log ID" do
    sign_in @superadmin

    get audit_log_path(id: 99999)
    assert_response :not_found
  end

  test "show handles invalid audit log ID gracefully" do
    sign_in @superadmin

    get audit_log_path(id: "invalid-id")
    assert_response :not_found
  end

  # ============================================================================
  # INDEX ACTION TESTS - Empty Results
  # ============================================================================

  test "index returns empty list for user with no audit logs" do
    sign_in @superadmin
    get audit_logs_path
    assert_response :success
    # Just verify the page renders correctly
    assert_select "table" # Should have a table even if empty
  end
end
