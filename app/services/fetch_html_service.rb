# frozen_string_literal: true

# Fetch HTML service is responsible for fetching the HTML content of a given URL.
class FetchHtmlService < ApplicationService
  class WebPageError < StandardError; end

  require 'http-cookie'

  USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)' \
               'Chrome/58.0.3029.110 Safari/537.3'

  def initialize(url)
    super()
    @url = url
    @cookie_jar = HTTP::CookieJar.new
  end

  def call
    response = make_request

    response.body
  rescue StandardError => e
    raise WebPageError, "Failed to fetch the page: #{e.message}"
  end

  private

  def make_request
    request = Net::HTTP::Get.new(@url)
    request['User-Agent'] = USER_AGENT
    request['Cookie'] = HTTP::Cookie.cookie_value(@cookie_jar.cookies(@url))

    response = Net::HTTP.start(@url.host, @url.port, use_ssl: @url.scheme == 'https') do |http|
      http.request(request)
    end

    store_cookies(response)

    response
  end

  def store_cookies(response)
    response.get_fields('Set-Cookie')&.each do |value|
      @cookie_jar.parse(value, @url)
    end
  end
end
