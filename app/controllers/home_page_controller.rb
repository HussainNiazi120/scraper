# frozen_string_literal: true

# Homepage controller
class HomePageController < ApplicationController
  def index; end

  def scrape
    @response = ScrapeService.call(scrape_params)
    @messages = @response.delete(:messages)

    respond_to(&:turbo_stream)
  rescue SanitizeUrlService::UrlMissingError, SanitizeUrlService::InvalidUrlError,
         ValidateFieldsService::MissingOrInvalidFields => e
    handle_error(e, 422)
  rescue FetchHtmlService::WebPageError => e
    handle_error(e, 500)
  rescue StandardError
    handle_unexpected_error
  end

  private

  def scrape_params
    params.permit(:url, :commit, fields: {})
  end

  def handle_error(error, code)
    @error = { code:, message: error.message }
    render_error
  end

  def handle_unexpected_error
    @error = { code: 500, message: 'There was an unexpected error' }
    render_error
  end

  def render_error
    respond_to do |format|
      format.turbo_stream { render 'scrape' }
      format.json { render json: @error, status: @error[:code] }
    end
  end
end
