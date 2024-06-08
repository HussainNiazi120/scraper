# frozen_string_literal: true

# Validate Fields Service validates fields
class ValidateFieldsService < ApplicationService
  class MissingOrInvalidFields < StandardError; end

  def initialize(fields)
    super()
    @fields = fields
  end

  def call
    sanitize_fields
    validate_fields
  end

  private

  def sanitize_fields
    @fields&.delete_if { |_, v| v.blank? }
  end

  def validate_fields
    raise MissingOrInvalidFields, 'Fields are missing or invalid' unless @fields.present?
  end
end
