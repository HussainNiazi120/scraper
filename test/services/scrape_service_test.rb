# frozen_string_literal: true

require 'test_helper'
require 'mocha/minitest'
require 'scraper_test_helper'

class ScrapeServiceTest < ActiveSupport::TestCase
  include ScraperTestHelper

  setup do
    @params = {
      url: 'https://www.alza.cz/aeg-7000-prosteam-lfr73964cc-d7635493.htm',
      fields: {
        price: '.price-box__price'
      }
    }

    @html = File.read(Rails.root.join('test', 'fixtures', 'files', 'simple_page_with_data.html'))
  end

  def parse_html(html)
    doc = Nokogiri::HTML(html)
    doc.search('script, style').remove
    doc
  end

  test 'fetch_html with uncached url and ensure script and style tags are removed before caching' do
    stub_valid_webpage

    Rails.cache.expects(:read).with(@params[:url]).returns(nil)
    Rails.cache.expects(:write).with(@params[:url], parse_html(@html).to_html, expires_in: 1.hour)

    assert_equal({ price: '20 890,-', messages: ['Fetched from URL'] }, ScrapeService.call(@params))
  end

  test 'fetch_html with cached url' do
    Net::HTTP::Get.expects(:new).never

    Rails.cache.expects(:read).with(@params[:url]).returns(@html)
    Rails.cache.expects(:write).never

    assert_equal({ price: '20 890,-', messages: ['Fetched from cache'] }, ScrapeService.call(@params))
  end
end
