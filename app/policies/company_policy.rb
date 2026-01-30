# frozen_string_literal: true

class CompanyPolicy < ApplicationPolicy
  def index?
    user.has_permission?("company_management.companies.index")
  end

  def show?
    user.has_permission?("company_management.companies.show")
  end

  def create?
    user.has_permission?("company_management.companies.create")
  end

  def update?
    user.has_permission?("company_management.companies.update")
  end

  def destroy?
    user.has_permission?("company_management.companies.destroy")
  end

  def confirm_delete?
    destroy?
  end

  def restore?
    user.has_permission?("company_management.companies.update")
  end

  def assign_users?
    update?
  end

  def update_users?
    update?
  end

  def remove_user?
    update?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
