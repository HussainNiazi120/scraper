# frozen_string_literal: true

# Homepage controller
class HomePageController < ApplicationController
  def index; end

  def scrape
    @response = ScrapeService.call(scrape_params)
    @messages = @response.delete(:messages)

    respond_to(&:turbo_stream)
  rescue StandardError => e
    handle_error(e)
  end

  private

  def scrape_params
    params.permit(:url, :commit, fields: {})
  end

  # rubocop:disable Metrics/MethodLength
  def handle_error(error)
    case error
    when SanitizeUrlService::UrlMissingError, SanitizeUrlService::InvalidUrlError,
         ValidateFieldsService::MissingOrInvalidFields
      @error = { code: 422, message: error.message }
    when FetchHtmlService::ForbiddenError
      @error = { code: 403, message: error.message }
    when FetchHtmlService::WebPageError
      @error = { code: 500, message: error.message }
      render_error
    else
      @error = { code: 500, message: 'There was an unexpected error' }
      render_error
    end
  end
  # rubocop:enable Metrics/MethodLength

  def render_error
    respond_to do |format|
      format.turbo_stream { render 'scrape' }
    end
  end
end
