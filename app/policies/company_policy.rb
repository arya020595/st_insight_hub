# frozen_string_literal: true

class CompanyPolicy < ApplicationPolicy
  # Inherit index?, show?, create?, update?, destroy?, confirm_delete? from ApplicationPolicy
  # They automatically check superadmin and permissions

  def assign_users?
    update?
  end

  def update_users?
    update?
  end

  def remove_user?
    update?
  end

  private

  def permission_resource
    "company_management.companies"
  end

  class Scope < ApplicationPolicy::Scope
    private

    def permission_resource
      "company_management.companies"
    end
  end
end
