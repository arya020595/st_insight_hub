# frozen_string_literal: true

module UserManagement
  class RolePolicy < ApplicationPolicy
    private

    def permission_resource
      "user_management.roles"
    end

    class Scope < ApplicationPolicy::Scope
      private

      def permission_resource
        "user_management.roles"
      end
    end
  end
end
