module ScrapperTestHelper
    def stub_valid_webpage
      html = File.read(Rails.root.join('test', 'fixtures', 'files', 'page.html'))
  
      stub_request(:get, "https://www.alza.cz/aeg-7000-prosteam-lfr73964cc-d7635493.htm").
        with(
          headers: {
                'Accept'=>'*/*',
                'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                'User-Agent'=>'Ruby'
          }).
        to_return(status: 200, body: html, headers: {})
    end

    def stub_valid_webpage_with_missing_data
      html = File.read(Rails.root.join('test', 'fixtures', 'files', 'page_with_missing_data.html'))
  
      stub_request(:get, "https://www.alza.cz/aeg-7000-prosteam-lfr73964cc-d7635493.htm").
        with(
          headers: {
                'Accept'=>'*/*',
                'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                'User-Agent'=>'Ruby'
          }).
        to_return(status: 200, body: html, headers: {})
    end
end
  