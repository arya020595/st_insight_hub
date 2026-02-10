# frozen_string_literal: true

# Concern for controllers that need audit logging functionality.
# Provides a simplified DSL for logging CRUD actions with automatic
# attribute capture for before/after states.
#
# Usage:
#   class ProjectsController < ApplicationController
#     include Auditable
#
#     def create
#       @project = Project.new(project_params)
#       if @project.save
#         audit_create(@project, module_name: "projects")
#         redirect_to projects_path
#       end
#     end
#
#     def update
#       audit_update(@project, module_name: "projects") do
#         @project.update(project_params)
#       end
#     end
#   end
#
module Auditable
  extend ActiveSupport::Concern

  private

  # Log a create action for a record
  # @param record [ActiveRecord::Base] the created record
  # @param module_name [String] the module/section name for categorization
  # @param summary [String, nil] optional custom summary (auto-generated if nil)
  def audit_create(record, module_name:, summary: nil)
    log_audit(
      action: "create",
      module_name: module_name,
      auditable: record,
      summary: summary || "Created #{record.model_name.human.downcase}: #{record_display_name(record)}",
      data_after: record.attributes
    )
  end

  # Log an update action for a record, capturing before/after state
  # @param record [ActiveRecord::Base] the record to update
  # @param module_name [String] the module/section name for categorization
  # @param summary [String, nil] optional custom summary (auto-generated if nil)
  # @yield block that performs the actual update
  # @return [Boolean] result of the update operation
  def audit_update(record, module_name:, summary: nil)
    data_before = record.attributes.dup
    result = yield

    if result
      log_audit(
        action: "update",
        module_name: module_name,
        auditable: record,
        summary: summary || "Updated #{record.model_name.human.downcase}: #{record_display_name(record)}",
        data_before: data_before,
        data_after: record.attributes
      )
    end

    result
  end

  # Log a delete/discard action for a record
  # @param record [ActiveRecord::Base] the deleted record
  # @param module_name [String] the module/section name for categorization
  # @param summary [String, nil] optional custom summary (auto-generated if nil)
  def audit_delete(record, module_name:, summary: nil)
    log_audit(
      action: "delete",
      module_name: module_name,
      auditable: record,
      summary: summary || "Deleted #{record.model_name.human.downcase}: #{record_display_name(record)}",
      data_before: record.attributes
    )
  end

  # Log a restore/undiscard action for a record
  # @param record [ActiveRecord::Base] the restored record
  # @param module_name [String] the module/section name for categorization
  # @param summary [String, nil] optional custom summary (auto-generated if nil)
  def audit_restore(record, module_name:, summary: nil)
    log_audit(
      action: "restore",
      module_name: module_name,
      auditable: record,
      summary: summary || "Restored #{record.model_name.human.downcase}: #{record_display_name(record)}",
      data_after: record.attributes
    )
  end

  # Get display name for a record (tries common name attributes)
  # @param record [ActiveRecord::Base] the record
  # @return [String] display name
  def record_display_name(record)
    if record.respond_to?(:name) && record.name.present?
      record.name
    elsif record.respond_to?(:title) && record.title.present?
      record.title
    else
      "##{record.id}"
    end
  end
end
