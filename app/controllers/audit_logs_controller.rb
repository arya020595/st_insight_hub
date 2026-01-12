# frozen_string_literal: true

class AuditLogsController < ApplicationController
  def index
    authorize AuditLog
    @q = policy_scope(AuditLog).ransack(params[:q])
    @q.sorts = 'created_at desc' if @q.sorts.empty?
    @pagy, @audit_logs = pagy(@q.result.includes(:user))
  end

  def show
    @audit_log = AuditLog.find(params[:id])
    authorize @audit_log
  end
end
