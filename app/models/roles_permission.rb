# frozen_string_literal: true

class RolesPermission < ApplicationRecord
  include Discard::Model

  belongs_to :role, touch: true
  belongs_to :permission

  validates :role_id, uniqueness: { scope: :permission_id }
end
