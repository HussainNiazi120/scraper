# frozen_string_literal: true

require 'net/http'

# Fetch HTML service is responsible for fetching the HTML content of a given URL.
class FetchHtmlService < ApplicationService
  class WebPageError < StandardError; end

  USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)' \
               'Chrome/58.0.3029.110 Safari/537.3'

  def initialize(url)
    super()
    @url = url
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

    Net::HTTP.start(@url.host, @url.port, use_ssl: @url.scheme == 'https') do |http|
      http.request(request)
    end
  end
end
