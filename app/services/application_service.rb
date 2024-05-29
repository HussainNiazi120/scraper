# frozen_string_literal: true

# The ApplicationService is the parent service in the application from which all other services inherit.
# It provides a common interface for calling services with the `call` class method.
class ApplicationService
  def self.call(*, &)
    new(*, &).call
  end
end
