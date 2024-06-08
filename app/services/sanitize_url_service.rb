# frozen_string_literal: true

require 'uri'

# Service to sanitize a URL ad raise errors if the URL is missing or invalid
class SanitizeUrlService < ApplicationService
  class UrlMissingError < StandardError; end
  class InvalidUrlError < StandardError; end

  VALID_SCHEMES = %w[http https].freeze

  def initialize(url)
    super()
    @url = url
  end

  def call
    validate_url_presence
    uri = URI.parse(@url)
    validate_url_scheme(uri)
    validate_url_host(uri)

    uri
  end

  private

  def validate_url_presence
    raise UrlMissingError, 'Missing URL' unless @url.present?
  end

  def validate_url_scheme(uri)
    raise InvalidUrlError, 'Invalid URL scheme' unless VALID_SCHEMES.include?(uri.scheme)
  end

  def validate_url_host(uri)
    raise InvalidUrlError, 'URL must have a host' unless uri.host
  end
end
