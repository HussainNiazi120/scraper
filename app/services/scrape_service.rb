# frozen_string_literal: true

require 'nokogiri'

# The ScrapeService is responsible for scraping data from a given URL.
# It calls the ValidateFieldsService to validate the fields and the SanitizeUrlService to sanitize the URL.
# It also calls the FetchHtmlService to fetch the HTML content of the URL.
# It then calls the ScrapeFieldsService to scrape the fields
# and meta tags from the HTML content and returns the scraped data.
class ScrapeService < ApplicationService
  def initialize(params)
    super()
    @params = params
    @url = params[:url]
    @fields = params[:fields]
    @messages = []
  end

  def call
    ValidateFieldsService.call(@fields)

    url = SanitizeUrlService.call(@params[:url])
    html = fetch_html(url)

    doc = Nokogiri::HTML(html)

    fields, meta_tags = ScrapeFieldsService.call(@fields, doc)

    build_response(fields, meta_tags)
  end

  private

  def fetch_html(url)
    html = Rails.cache.read(url.to_s)

    if html
      @messages << 'Fetched from cache'
    else
      html = FetchHtmlService.call(url)
      @messages << 'Fetched from URL'
      Rails.cache.write(url.to_s, sanitize_html(html), expires_in: 1.hour)
    end

    html
  end

  def sanitize_html(html)
    doc = Nokogiri::HTML(html)
    doc.search('script, style').remove
    doc.to_html
  end

  def build_response(fields, meta_tags)
    @response = fields
    @response[:meta] = meta_tags if meta_tags.present?
    @response.merge(messages: @messages)
  end
end
