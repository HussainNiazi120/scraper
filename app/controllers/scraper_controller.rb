# frozen_string_literal: true

# The ScraperController handles the web scraping functionality of the application.
# It uses the ScrapeService to scrape data from a given URL and returns the scraped data.
class ScraperController < ApplicationController
  rescue_from ScrapeService::UrlMissingError, with: :handle_url_missing
  rescue_from ScrapeService::InvalidUrlError, with: :handle_invalid_url_error
  rescue_from ScrapeService::MissingOrInvalidFields, with: :handle_missing_or_invalid_fields
  rescue_from ScrapeService::WebPageError, with: :handle_webpage_error

  def index; end

  def scrape
    @response = ScrapeService.call(scrape_params)
    @messages = @response.delete(:messages)

    respond_to do |format|
      format.turbo_stream
      format.json { render json: @response }
    end
  end

  private

  def scrape_params
    params.permit(:url, :commit, fields: {})
  end

  def handle_url_missing
    @error = { code: 422, message: 'URL is missing' }
    render_error
  end

  def handle_invalid_url_error
    @error = { code: 422, message: 'URL is invalid' }
    render_error
  end

  def handle_missing_or_invalid_fields
    @error = { code: 422, message: 'Fields are missing or invalid' }
    render_error
  end

  def handle_webpage_error(message)
    @error = { code: 500, message: }
    render_error
  end

  def render_error
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace('formErrors', partial: 'form_errors') }
      format.json { render json: @error, status: @error[:code] }
    end
  end
end
