# frozen_string_literal: true

module ScraperTestHelper
  def stub_valid_webpage
    html = load_html('simple_page_with_data.html')
    stub_webpage('https://www.alza.cz/aeg-7000-prosteam-lfr73964cc-d7635493.htm', html, 200)
  end

  def stub_valid_real_webpage
    html = load_html('real_page.html')
    stub_webpage('https://www.alza.cz/aeg-7000-prosteam-lfr73964cc-d7635493.htm', html, 200)
  end

  def stub_valid_webpage_with_missing_data
    html = load_html('page_with_missing_data.html')
    stub_webpage('https://www.alza.cz/aeg-7000-prosteam-lfr73964cc-d7635493.htm', html, 200)
  end

  def stub_invalid_webpage
    stub_webpage('https://error_page.com', '', 500)
  end

  private

  def load_html(filename)
    File.read(Rails.root.join('test', 'fixtures', 'files', filename))
  end

  def stub_webpage(url, body, status)
    stub_request(:get, url)
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent' => 'Ruby'
        }
      )
      .to_return(status:, body:, headers: {})
  end
end
