# frozen_string_literal: true

class ProjectUser < ApplicationRecord
  belongs_to :project
  belongs_to :user

  validates :project_id, uniqueness: { scope: :user_id, message: "user already assigned to this project" }
end
