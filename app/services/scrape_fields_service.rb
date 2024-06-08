# frozen_string_literal: true

# Scrape Fields Service scrapes fields and meta tags from a document
class ScrapeFieldsService < ApplicationService
  def initialize(fields, doc)
    super()
    @fields = fields
    @doc = doc
  end

  def call
    prepare_meta_tags

    [scrape_fields, scrape_meta_tags]
  end

  private

  def prepare_meta_tags
    @meta_tags = @fields.delete(:meta) if @fields.present? && @fields[:meta].present?

    @meta_tags&.delete_if(&:blank?)
  end

  def scrape_fields
    fields = {}
    @fields.each do |field|
      fields[field[0]] = @doc.css(field[1]).text.present? ? @doc.css(field[1]).text : nil
    end
    fields
  end

  def scrape_meta_tags
    return unless @meta_tags.present?

    meta = {}
    @meta_tags.each do |tag|
      value = @doc.css("meta[name='#{tag}']").first&.[]('content')
      meta[tag] = value if value.present?
    end
    meta if meta.present?
  end
end
