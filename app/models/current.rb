# frozen_string_literal: true

# Stores the current user for access in models
class Current < ActiveSupport::CurrentAttributes
  attribute :user
end
