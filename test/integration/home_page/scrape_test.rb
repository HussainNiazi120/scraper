# frozen_string_literal: true

require 'test_helper'
require 'scraper_test_helper'

class ScraperScrapeTest < ActionDispatch::IntegrationTest
  include ScraperTestHelper

  def setup
    @params = {
      url: 'https://www.alza.cz/aeg-7000-prosteam-lfr73964cc-d7635493.htm',
      fields: {
        meta: ['keywords', 'twitter:image'],
        price: '.price-box__price',
        rating_count: '.ratingCount',
        rating_value: '.ratingValue'
      }
    }
  end

  test 'turbo_stream format with valid json request' do
    stub_valid_webpage

    post scrape_path, params: @params.to_json,
                      headers: { 'CONTENT_TYPE' => 'application/json',
                                 'HTTP_ACCEPT' => 'text/vnd.turbo-stream.html' }
    assert_equal 200, @response.status
    assert_equal 'text/vnd.turbo-stream.html; charset=utf-8', @response.content_type

    assert_match(/<turbo-stream action="replace" target="response">/, @response.body)
  end

  test 'turbo_stream format with invalid request' do
    stub_valid_webpage

    params = {
      url: 'www.invalid-url',
      fields: {
        price: '.price-box__price'
      }
    }
    post scrape_path, params: params.to_json,
                      headers: { 'CONTENT_TYPE' => 'application/json',
                                 'HTTP_ACCEPT' => 'text/vnd.turbo-stream.html' }
    assert_equal 200, @response.status
    assert_equal 'text/vnd.turbo-stream.html; charset=utf-8', @response.content_type

    assert_match(/<turbo-stream action="replace" target="formErrors">/, @response.body)
    assert_match(%r{<b>422</b> : Invalid URL scheme}, @response.body)
  end
end
