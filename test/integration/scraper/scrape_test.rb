# frozen_string_literal: true

require 'test_helper'
require 'scraper_test_helper'

class ScraperScrapTest < ActionDispatch::IntegrationTest
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

  test 'with valid json request' do
    stub_valid_webpage

    post scrape_path, params: @params, as: :json
    assert_equal 200, @response.status

    data = @response.parsed_body
    assert_equal '20 890,-', data['price']
    assert_equal '7 hodnocení', data['rating_count']
    assert_equal '4,9', data['rating_value']
    expected_keywords = 'AEG,7000,ProSteam®,LFR73964CC,Automatické pračky,' \
                        'Automatické pračky AEG,Chytré pračky,Chytré pračky AEG'
    assert_equal expected_keywords, data['meta']['keywords']
  end

  test 'with valid json request with only meta tags' do
    stub_valid_webpage

    params = {
      url: 'https://www.alza.cz/aeg-7000-prosteam-lfr73964cc-d7635493.htm',
      fields: {
        meta: ['keywords', 'twitter:image']
      }
    }
    post scrape_path, params:, as: :json
    assert_equal 200, @response.status

    data = @response.parsed_body
    expected_keywords = 'AEG,7000,ProSteam®,LFR73964CC,Automatické pračky,' \
                        'Automatické pračky AEG,Chytré pračky,Chytré pračky AEG'
    assert_equal expected_keywords, data['meta']['keywords']
  end

  test 'with valid request on real webpage' do
    stub_valid_real_webpage

    params = {
      url: 'https://www.alza.cz/aeg-7000-prosteam-lfr73964cc-d7635493.htm',
      fields: {
        meta: ['keywords', 'twitter:image']
      }
    }
    post scrape_path, params:, as: :json
    assert_equal 200, @response.status

    data = @response.parsed_body
    expected_keywords = 'AEG,7000,ProSteam®,LFR73964CC,Automatické pračky,' \
                        'Automatické pračky AEG,Chytré pračky,Chytré pračky AEG'
    assert_equal expected_keywords, data['meta']['keywords']
  end

  test 'with valid json request but missing data in webpage' do
    stub_valid_webpage_with_missing_data

    post scrape_path, params: @params, as: :json
    assert_equal 200, @response.status

    data = @response.parsed_body

    assert_not data['price']
    assert_not data['rating_count']
    assert_not data['rating_value']
    assert_not data['meta']['keywords']
    assert_not data['meta']['twitter:image']
  end

  test 'with invalid request - missing url' do
    params = {
      url: nil,
      fields: {
        price: '.price-box__price'
      }
    }
    post scrape_path, params:, as: :json
    assert_equal 422, @response.status

    data = @response.parsed_body
    assert_equal 422, data['code']
    assert_equal 'URL is missing', data['message']
  end

  test 'with invalid request - invalid url' do
    params = {
      url: 'www.invalid-url',
      fields: {
        price: '.price-box__price'
      }
    }
    post scrape_path, params:, as: :json
    assert_equal 422, @response.status

    data = @response.parsed_body
    assert_equal 422, data['code']
    assert_equal 'URL is invalid', data['message']
  end

  test 'with invalid request - missing fields' do
    params = {
      url: 'https://www.alza.cz/aeg-7000-prosteam-lfr73964cc-d7635493.htm'
    }
    post scrape_path, params:, as: :json

    assert_equal 422, @response.status

    data = @response.parsed_body
    assert_equal 422, data['code']
    assert_equal 'Fields are missing or invalid', data['message']
  end

  test 'with exception raised - Socket::ResolutionError' do
    stub_invalid_webpage

    URI.stubs(:open).raises(
      Socket::ResolutionError.new('Failed to open TCP connection to error_page.com:443' \
                                  '(getaddrinfo: Name or service not known)')
    )

    params = {
      url: 'https://error_page.com',
      fields: {
        price: '.price-box__price'
      }
    }

    post scrape_path, params:, as: :json

    data = @response.parsed_body
    assert_equal 500, @response.status
    assert_equal 'Failed to fetch the page: ', data['message']
  end

  test 'without meta fields' do
    stub_valid_webpage

    params = {
      url: 'https://www.alza.cz/aeg-7000-prosteam-lfr73964cc-d7635493.htm',
      fields: {
        price: '.price-box__price'
      }
    }

    post scrape_path, params:, as: :json
    assert_equal 200, @response.status

    data = @response.parsed_body
    assert_equal '20 890,-', data['price']
    assert_not data['meta']
  end

  test 'turbo_stream format with valid json request' do
    stub_valid_webpage

    post scrape_path, params: @params.to_json,
                      headers: { 'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'text/vnd.turbo-stream.html' }
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
                      headers: { 'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'text/vnd.turbo-stream.html' }
    assert_equal 200, @response.status
    assert_equal 'text/vnd.turbo-stream.html; charset=utf-8', @response.content_type

    assert_match(/<turbo-stream action="replace" target="formErrors">/, @response.body)
    assert_match(%r{<b>422</b> : URL is invalid}, @response.body)
  end
end
