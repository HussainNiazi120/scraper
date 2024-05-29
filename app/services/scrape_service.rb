# frozen_string_literal: true

# The ScrapeService is responsible for scraping data from a given URL.
# It validates the URL and the fields to be scraped, and raises appropriate errors if they are missing or invalid.
# It inherits from the ApplicationService, and its functionality can be invoked using the `call` class method.
# It uses Nokogiri to parse the HTML content of the page and extract the required fields.
# It also caches the HTML content of the page using Redis to avoid repeated requests to the same URL.
# It returns the scraped data as a hash with the requested fields and their values.
# It also extracts the meta tags from the page if requested and adds them to the response.
# It raises a WebPageError if there is an issue with connecting to the URL or parsing the HTML content.
# It is used by the ScraperController to scrape data from a given URL and return the scraped data.
class ScrapeService < ApplicationService
  require 'uri'
  require 'net/http'
  require 'nokogiri'
  class UrlMissingError < StandardError; end
  class InvalidUrlError < StandardError; end
  class MissingOrInvalidFields < StandardError; end
  class WebPageError < StandardError; end

  def initialize(params)
    super()
    @params = params
    @url = params[:url]
    @fields = sanitize_fields
    @meta_tags = meta_tags
    @messages = []
  end

  def call
    validate_fields
    page = parse_html(fetch_html)
    @response = {}
    scrape_fields(page)
    @response[:meta] = scrape_meta_tags(page) if @meta_tags.present?
    @response.merge(messages: @messages)
  rescue UrlMissingError, InvalidUrlError, MissingOrInvalidFields => e
    raise e.class
  rescue StandardError => e
    raise WebPageError, e.message
  end

  private

  def sanitize_fields
    @params[:fields]&.delete_if { |_, v| v.nil? || v.empty? }
  end

  def meta_tags
    tags = @fields.delete(:meta) if @fields.present? && @fields[:meta].present?

    tags&.delete_if(&:blank?)
  end

  def validate_fields
    @fields = @fields&.select { |k, v| k.present? && v.present? }
    raise MissingOrInvalidFields unless @fields.present? || @meta_tags.present?
  end

  def sanitize_url(url)
    raise UrlMissingError unless url.present?

    # Use URI.parse to check if the URL is valid
    uri = URI.parse(url)
    # Check if the URI scheme is HTTP or HTTPS
    raise InvalidUrlError, 'Invalid URL scheme' unless %w[http https].include?(uri.scheme)
    # Check if the URI host is present
    raise InvalidUrlError, 'URL must have a host' unless uri.host

    # Return the sanitized URL
    uri.to_s
  rescue URI::InvalidURIError
    raise InvalidUrlError, 'Invalid URL format'
  end

  def fetch_html
    url = URI.parse(sanitize_url(@url))
    html = cached_html(url)
    @messages << 'Fetched from cache' and return html if html

    fetch_and_cache_html(url)
  end

  def cached_html(url)
    Rails.cache.read(url.to_s)
  end

  def fetch_and_cache_html(url)
    request = Net::HTTP::Get.new(url)

    response = Net::HTTP.start(url.host, url.port, use_ssl: url.scheme == 'https') do |http|
      http.request(request)
    end

    raise WebPageError, "Failed to fetch the page: #{response.message}" if response.code != '200'

    html = response.body
    Rails.cache.write(url.to_s, html, expires_in: 1.hour)
    @messages << 'Fetched from URL'
    html
  end

  def parse_html(html)
    doc = Nokogiri::HTML(html)
    doc.search('script, style').remove
    doc
  end

  def scrape_fields(page)
    @fields.each do |field|
      @response[field[0]] = page.css(field[1]).text.present? ? page.css(field[1]).text : nil
    end
  end

  def scrape_meta_tags(page)
    @meta_tags.each_with_object({}) do |tag, meta|
      meta[tag] = page.css("meta[name='#{tag}']").first&.[]('content')
    end
  end
end
