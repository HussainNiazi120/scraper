# frozen_string_literal: true

# Fetch HTML service is responsible for fetching the HTML content of a given URL.
class FetchHtmlService < ApplicationService
  class WebPageError < StandardError; end
  class ForbiddenError < StandardError; end

  require 'net/http'
  require 'http-cookie'

  USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' \
               '(KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0'

  def initialize(url)
    super()
    @url = url
    @cookie_jar = HTTP::CookieJar.new
  end

  def call
    response = make_request

    raise ForbiddenError if response.code == '403'

    response.body
  rescue ForbiddenError
    raise ForbiddenError, 'The page is forbidden to access by our server!'
  rescue StandardError => e
    raise WebPageError, "Failed to fetch the page: #{e.message}"
  ensure
    @cookie_jar.clear
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
